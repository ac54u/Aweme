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

// 💥 真正的终极绝杀：无视任何高质量/高保真/长音频，时空截断 + 柔和重铸！
+ (BOOL)hardTranscodeAudioFrom:(NSString *)srcPath to:(NSString *)dstPath {
    NSURL *srcURL = [NSURL fileURLWithPath:srcPath];
    NSURL *dstURL = [NSURL fileURLWithPath:dstPath];
    NSFileManager *fm = [NSFileManager defaultManager];
    if ([fm fileExistsAtPath:dstPath]) [fm removeItemAtPath:dstPath error:nil];
    
    AVAsset *asset = [AVAsset assetWithURL:srcURL];
    NSError *error = nil;
    
    AVAssetReader *reader = [AVAssetReader assetReaderWithAsset:asset error:&error];
    if (!reader) return NO;
    
    // 🌟 终极神技【时空截断】：大文件/长音频的克星！
    // 不管文件多大，只抽取前 29.5 秒进行解码，彻底告别内存爆炸和漫长等待！
    CMTime duration = asset.duration;
    if (CMTimeGetSeconds(duration) > 29.5) {
        reader.timeRange = CMTimeRangeMake(kCMTimeZero, CMTimeMakeWithSeconds(29.5, 600));
    }
    
    AVAssetTrack *audioTrack = [[asset tracksWithMediaType:AVMediaTypeAudio] firstObject];
    if (!audioTrack) return NO;
    
    // 🌟 核心防御 1【顺水推舟】：绝不在读取端强行降频！
    // 让它输出最原始、最自然的 PCM 波形，哪怕它是 192kHz 的怪物！
    NSDictionary *readerSettings = @{
        AVFormatIDKey: @(kAudioFormatLinearPCM)
    };
    AVAssetReaderTrackOutput *readerOutput = [AVAssetReaderTrackOutput assetReaderTrackOutputWithTrack:audioTrack outputSettings:readerSettings];
    [reader addOutput:readerOutput];
    
    AVAssetWriter *writer = [AVAssetWriter assetWriterWithURL:dstURL fileType:AVFileTypeAppleM4A error:&error];
    if (!writer) return NO;
    
    AudioChannelLayout channelLayout;
    memset(&channelLayout, 0, sizeof(AudioChannelLayout));
    channelLayout.mChannelLayoutTag = kAudioChannelLayoutTag_Mono;
    NSData *channelLayoutData = [NSData dataWithBytes:&channelLayout length:sizeof(AudioChannelLayout)];
    
    // 🌟 核心防御 2【降维打击】：在写入端进行降频，苹果底层会自动调用最优的软件重采样器
    NSDictionary *writerSettings = @{
        AVFormatIDKey: @(kAudioFormatMPEG4AAC),
        AVSampleRateKey: @(16000.0),
        AVNumberOfChannelsKey: @(1),
        AVEncoderBitRateKey: @(32000),
        AVChannelLayoutKey: channelLayoutData
    };
    
    AVAssetWriterInput *writerInput = [AVAssetWriterInput assetWriterInputWithMediaType:AVMediaTypeAudio outputSettings:writerSettings];
    writerInput.expectsMediaDataInRealTime = NO;
    if ([writer canAddInput:writerInput]) {
        [writer addInput:writerInput];
    } else {
        return NO;
    }
    
    [reader startReading];
    [writer startWriting];
    
    dispatch_semaphore_t sema = dispatch_semaphore_create(0);
    __block BOOL success = NO;
    
    // 🌟 核心防御 3【稳健搬运工】：用最原始的 while 循环替代闭包，杜绝回调错乱
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0), ^{
        BOOL isFirstBuffer = YES;
        
        while (reader.status == AVAssetReaderStatusReading) {
            if (writerInput.isReadyForMoreMediaData) {
                CMSampleBufferRef buffer = [readerOutput copyNextSampleBuffer];
                if (buffer) {
                    if (isFirstBuffer) {
                        // 精准捕获真实第一帧时间，完美包容负数时间戳！
                        CMTime pts = CMSampleBufferGetPresentationTimeStamp(buffer);
                        [writer startSessionAtSourceTime:pts];
                        isFirstBuffer = NO;
                    }
                    [writerInput appendSampleBuffer:buffer];
                    CFRelease(buffer);
                } else {
                    // 读取完毕 (可能是读到了 29.5 秒的截断处)
                    [writerInput markAsFinished];
                    break;
                }
            } else {
                // 写入器消化太慢，休息 5 毫秒防 CPU 飙升
                [NSThread sleepForTimeInterval:0.005];
            }
        }
        
        // 扫尾工作
        if (reader.status == AVAssetReaderStatusCompleted && !isFirstBuffer) {
            [writer finishWritingWithCompletionHandler:^{
                success = (writer.status == AVAssetWriterStatusCompleted);
                dispatch_semaphore_signal(sema);
            }];
        } else {
            [writer cancelWriting];
            dispatch_semaphore_signal(sema);
        }
    });
    
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
