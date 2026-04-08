#import "DYYYVoiceChanger.h"

static BOOL _isAudioAssistantActive = NO;

@implementation DYYYVoiceChanger

+ (void)setAudioAssistantActive:(BOOL)active {
    _isAudioAssistantActive = active;
    NSLog(@"[DYYYVoiceChanger] 🎛️ 音频助手状态: %@", active ? @"极速提纯模式" : @"拦截模式");
}

+ (BOOL)isAudioAssistantActive {
    return _isAudioAssistantActive;
}

+ (BOOL)processAudioFileFrom:(NSString *)srcPath to:(NSString *)dstPath {
    NSInteger voiceType = [[NSUserDefaults standardUserDefaults] integerForKey:@"DYYYVoiceChangerType"];
    
    // 音频助手发来的，强制进入 0 号极速提纯通道
    if ([self isAudioAssistantActive]) {
        voiceType = 0; 
    }
    
    // ==========================================
    // ⚡️ 核弹级提纯通道 (AVAssetReader/Writer)
    // 无视假后缀，强行解码并重铸为 16000Hz 单声道 M4A
    // ==========================================
    if (voiceType == 0) {
        NSLog(@"[DYYYVoiceChanger] ⚡️ 启动底层提纯重铸机...");
        return [self hardTranscodeAudioFrom:srcPath to:dstPath];
    }
    
    // 🎛️ 以下是变声特效通道 (保持原有逻辑)
    NSFileManager *fm = [NSFileManager defaultManager];
    __block BOOL processSuccess = NO;
    dispatch_semaphore_t semaphore = dispatch_semaphore_create(0);
    
    [self processAudioAtPath:srcPath withVoiceType:voiceType completion:^(NSString *outputPath, NSError *error) {
        if (outputPath) {
            if ([fm fileExistsAtPath:dstPath]) [fm removeItemAtPath:dstPath error:nil];
            processSuccess = [fm moveItemAtPath:outputPath toPath:dstPath error:nil];
        }
        dispatch_semaphore_signal(semaphore);
    }];
    
    dispatch_semaphore_wait(semaphore, DISPATCH_TIME_FOREVER);
    return processSuccess;
}

// 💥 真正的绝杀：不管你什么格式，全部打碎重铸！
+ (BOOL)hardTranscodeAudioFrom:(NSString *)srcPath to:(NSString *)dstPath {
    NSURL *srcURL = [NSURL fileURLWithPath:srcPath];
    NSURL *dstURL = [NSURL fileURLWithPath:dstPath];
    NSFileManager *fm = [NSFileManager defaultManager];
    if ([fm fileExistsAtPath:dstPath]) [fm removeItemAtPath:dstPath error:nil];
    
    AVAsset *asset = [AVAsset assetWithURL:srcURL];
    NSError *error = nil;
    
    // 1. 读取器：强行读取源文件
    AVAssetReader *reader = [AVAssetReader assetReaderWithAsset:asset error:&error];
    if (!reader) return NO;
    
    AVAssetTrack *audioTrack = [[asset tracksWithMediaType:AVMediaTypeAudio] firstObject];
    if (!audioTrack) return NO;
    
    // 将任何音频解码为原始 PCM 波形
    NSDictionary *readerSettings = @{ AVFormatIDKey: @(kAudioFormatLinearPCM) };
    AVAssetReaderTrackOutput *readerOutput = [AVAssetReaderTrackOutput assetReaderTrackOutputWithTrack:audioTrack outputSettings:readerSettings];
    [reader addOutput:readerOutput];
    
    // 2. 写入器：铸造纯正的抖音标准 M4A
    AVAssetWriter *writer = [AVAssetWriter assetWriterWithURL:dstURL fileType:AVFileTypeAppleM4A error:&error];
    if (!writer) return NO;
    
    // 强制 16000Hz, 单声道, AAC 编码
    AudioChannelLayout channelLayout;
    memset(&channelLayout, 0, sizeof(AudioChannelLayout));
    channelLayout.mChannelLayoutTag = kAudioChannelLayoutTag_Mono;
    NSData *channelLayoutData = [NSData dataWithBytes:&channelLayout length:sizeof(AudioChannelLayout)];
    
    NSDictionary *writerSettings = @{
        AVFormatIDKey: @(kAudioFormatMPEG4AAC),
        AVSampleRateKey: @(16000.0),
        AVNumberOfChannelsKey: @(1),
        AVEncoderBitRateKey: @(32000),
        AVChannelLayoutKey: channelLayoutData
    };
    
    AVAssetWriterInput *writerInput = [AVAssetWriterInput assetWriterInputWithMediaType:AVMediaTypeAudio outputSettings:writerSettings];
    writerInput.expectsMediaDataInRealTime = NO;
    [writer addInput:writerInput];
    
    [reader startReading];
    [writer startWriting];
    [writer startSessionAtSourceTime:kCMTimeZero];
    
    dispatch_queue_t queue = dispatch_queue_create("com.dyyy.transcode", NULL);
    dispatch_semaphore_t sema = dispatch_semaphore_create(0);
    __block BOOL success = NO;
    
    // 3. 流水线开启：一边读取，一边裁剪，一边重铸！
    [writerInput requestMediaDataWhenReadyOnQueue:queue usingBlock:^{
        while (writerInput.isReadyForMoreMediaData) {
            CMSampleBufferRef sampleBuffer = [readerOutput copyNextSampleBuffer];
            if (sampleBuffer) {
                // ✂️ 完美裁剪：超过 29.5 秒立刻掐断！
                CMTime presentationTime = CMSampleBufferGetPresentationTimeStamp(sampleBuffer);
                if (CMTimeGetSeconds(presentationTime) > 29.5) {
                    CFRelease(sampleBuffer);
                    [writerInput markAsFinished];
                    break;
                }
                [writerInput appendSampleBuffer:sampleBuffer];
                CFRelease(sampleBuffer);
            } else {
                [writerInput markAsFinished];
                break;
            }
        }
        
        if (reader.status == AVAssetReaderStatusCompleted || reader.status == AVAssetReaderStatusFailed || !writerInput.isReadyForMoreMediaData) {
            [writer finishWritingWithCompletionHandler:^{
                success = (writer.status == AVAssetWriterStatusCompleted);
                dispatch_semaphore_signal(sema);
            }];
        }
    }];
    
    dispatch_semaphore_wait(sema, DISPATCH_TIME_FOREVER);
    return success;
}

// --- 变声特效渲染器 (保持不变) ---
+ (void)processAudioAtPath:(NSString *)inputPath withVoiceType:(NSInteger)voiceType completion:(void(^)(NSString *outputPath, NSError *error))completion {
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0), ^{
        NSURL *sourceURL = [NSURL fileURLWithPath:inputPath];
        NSError *error = nil;
        AVAudioFile *sourceFile = [[AVAudioFile alloc] initForReading:sourceURL error:&error];
        if (error || !sourceFile) { if(completion) completion(nil, error); return; }
        
        AVAudioEngine *engine = [[AVAudioEngine alloc] init];
        AVAudioPlayerNode *playerNode = [[AVAudioPlayerNode alloc] init];
        [engine attachNode:playerNode];
        
        NSMutableArray<AVAudioNode *> *audioNodes = [NSMutableArray array];
        if (voiceType == 1) { AVAudioUnitTimePitch *pitch = [[AVAudioUnitTimePitch alloc] init]; pitch.pitch = 1000.0; [engine attachNode:pitch]; [audioNodes addObject:pitch]; } 
        else if (voiceType == 2) { AVAudioUnitTimePitch *pitch = [[AVAudioUnitTimePitch alloc] init]; pitch.pitch = -800.0; [engine attachNode:pitch]; [audioNodes addObject:pitch]; } 
        else if (voiceType == 3) { AVAudioUnitReverb *reverb = [[AVAudioUnitReverb alloc] init]; [reverb loadFactoryPreset:AVAudioUnitReverbPresetLargeHall]; reverb.wetDryMix = 50.0; [engine attachNode:reverb]; [audioNodes addObject:reverb]; } 
        else if (voiceType == 4) { AVAudioUnitDistortion *distortion = [[AVAudioUnitDistortion alloc] init]; [distortion loadFactoryPreset:AVAudioUnitDistortionPresetSpeechRadioTower]; distortion.wetDryMix = 70.0; [engine attachNode:distortion]; [audioNodes addObject:distortion]; } 
        else if (voiceType == 5) { AVAudioUnitTimePitch *pitch = [[AVAudioUnitTimePitch alloc] init]; pitch.pitch = -1200.0; [engine attachNode:pitch]; [audioNodes addObject:pitch]; AVAudioUnitReverb *reverb = [[AVAudioUnitReverb alloc] init]; [reverb loadFactoryPreset:AVAudioUnitReverbPresetMediumChamber]; reverb.wetDryMix = 40.0; [engine attachNode:reverb]; [audioNodes addObject:reverb]; }
        
        AVAudioFormat *sourceFormat = sourceFile.processingFormat;
        AVAudioNode *previousNode = playerNode;
        for (AVAudioNode *node in audioNodes) { [engine connect:previousNode to:node format:sourceFormat]; previousNode = node; }
        [engine connect:previousNode to:engine.mainMixerNode format:sourceFormat];
        
        AVAudioFormat *monoBufferFormat = [[AVAudioFormat alloc] initStandardFormatWithSampleRate:sourceFormat.sampleRate channels:1];
        [engine enableManualRenderingMode:AVAudioEngineManualRenderingModeOffline format:monoBufferFormat maximumFrameCount:4096 error:&error];
        if (error) { if(completion) completion(nil, error); return; }
        
        [engine startAndReturnError:&error];
        if (error) { if(completion) completion(nil, error); return; }
        
        [playerNode scheduleFile:sourceFile atTime:nil completionHandler:nil];
        [playerNode play];
        
        NSString *outFileName = [NSString stringWithFormat:@"dyyy_fx_%@.m4a", [[NSUUID UUID] UUIDString]];
        NSString *outputPath = [NSTemporaryDirectory() stringByAppendingPathComponent:outFileName];
        
        NSDictionary *outputSettings = @{ AVFormatIDKey: @(kAudioFormatMPEG4AAC), AVSampleRateKey: @(16000.0), AVNumberOfChannelsKey: @(1), AVEncoderBitRateKey: @(32000) };
        AVAudioFile *outputFile = [[AVAudioFile alloc] initForWriting:[NSURL fileURLWithPath:outputPath] settings:outputSettings commonFormat:monoBufferFormat.commonFormat interleaved:monoBufferFormat.isInterleaved error:&error];
        if (error || !outputFile) { if(completion) completion(nil, error); return; }
        
        AVAudioPCMBuffer *buffer = [[AVAudioPCMBuffer alloc] initWithPCMFormat:monoBufferFormat frameCapacity:engine.manualRenderingMaximumFrameCount];
        
        while (YES) {
            AVAudioEngineManualRenderingStatus status = [engine renderOffline:buffer.frameCapacity toBuffer:buffer error:&error];
            if (status == AVAudioEngineManualRenderingStatusSuccess) {
                [outputFile writeFromBuffer:buffer error:&error];
                if (error) break;
            } else {
                break;
            }
        }
        
        [playerNode stop]; [engine stop];
        if (error) { if(completion) completion(nil, error); } else { if(completion) completion(outputPath, nil); }
    });
}
@end
