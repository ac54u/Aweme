#import "DYYYVoiceChanger.h"

static BOOL _isAudioAssistantActive = NO;

@implementation DYYYVoiceChanger

// 🚀 状态管理
+ (void)setAudioAssistantActive:(BOOL)active {
    _isAudioAssistantActive = active;
    NSLog(@"[DYYYVoiceChanger] 🎛️ 音频助手状态已切换为: %@", active ? @"开启 (强制洗澡瘦身模式)" : @"关闭 (拦截模式)");
}

+ (BOOL)isAudioAssistantActive {
    return _isAudioAssistantActive;
}

// --- 供 Hook 调用的同步方法 ---
+ (BOOL)processAudioFileFrom:(NSString *)srcPath to:(NSString *)dstPath {
    NSInteger voiceType = [[NSUserDefaults standardUserDefaults] integerForKey:@"DYYYVoiceChangerType"];
    
    if ([self isAudioAssistantActive]) {
        NSLog(@"[DYYYVoiceChanger] 🎧 音频助手正在工作，放行原声文件并执行强制格式瘦身！");
        voiceType = 0; 
    }
    
    __block BOOL processSuccess = NO;
    dispatch_semaphore_t semaphore = dispatch_semaphore_create(0);
    
    [self processAudioAtPath:srcPath withVoiceType:voiceType completion:^(NSString *outputPath, NSError *error) {
        if (error || !outputPath) {
            NSLog(@"[DYYYVoiceChanger] ❌ 音频核心处理失败: %@", error.localizedDescription);
            processSuccess = NO;
        } else {
            NSFileManager *fm = [NSFileManager defaultManager];
            if ([fm fileExistsAtPath:dstPath]) [fm removeItemAtPath:dstPath error:nil];
            NSError *moveError = nil;
            processSuccess = [fm moveItemAtPath:outputPath toPath:dstPath error:&moveError];
        }
        dispatch_semaphore_signal(semaphore);
    }];
    
    // 🚨 核心修复 2：解除变声渲染超时封印！彻底等待大文件转换完毕！
    dispatch_semaphore_wait(semaphore, DISPATCH_TIME_FOREVER);
    return processSuccess;
}

// 🛡️ 终极兜底
+ (void)fallbackExportAudio:(NSURL *)sourceURL completion:(void(^)(NSString *outputPath, NSError *error))completion {
    NSLog(@"[DYYYVoiceChanger] ⚠️ 触发终极兜底转码机制！");
    NSString *outFileName = [NSString stringWithFormat:@"dyyy_fallback_%@.m4a", [[NSUUID UUID] UUIDString]];
    NSString *outputPath = [NSTemporaryDirectory() stringByAppendingPathComponent:outFileName];
    
    AVAsset *asset = [AVAsset assetWithURL:sourceURL];
    AVAssetExportSession *exportSession = [AVAssetExportSession exportSessionWithAsset:asset presetName:AVAssetExportPresetAppleM4A];
    exportSession.outputURL = [NSURL fileURLWithPath:outputPath];
    exportSession.outputFileType = AVFileTypeAppleM4A;
    
    [exportSession exportAsynchronouslyWithCompletionHandler:^{
        if (exportSession.status == AVAssetExportSessionStatusCompleted) {
            if (completion) completion(outputPath, nil);
        } else {
            if (completion) completion(nil, exportSession.error);
        }
    }];
}

// --- 核心变声及格式化方法 ---
+ (void)processAudioAtPath:(NSString *)inputPath
             withVoiceType:(NSInteger)voiceType
                completion:(void(^)(NSString *outputPath, NSError *error))completion {
    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0), ^{
        NSURL *sourceURL = [NSURL fileURLWithPath:inputPath];
        NSError *error = nil;
        
        AVAudioFile *sourceFile = [[AVAudioFile alloc] initForReading:sourceURL error:&error];
        if (error || !sourceFile) { 
            [self fallbackExportAudio:sourceURL completion:completion];
            return; 
        }
        
        AVAudioEngine *engine = [[AVAudioEngine alloc] init];
        AVAudioPlayerNode *playerNode = [[AVAudioPlayerNode alloc] init];
        [engine attachNode:playerNode];
        
        NSMutableArray<AVAudioNode *> *audioNodes = [NSMutableArray array];
        
        if (voiceType == 1) {
            AVAudioUnitTimePitch *pitch = [[AVAudioUnitTimePitch alloc] init];
            pitch.pitch = 1000.0; [engine attachNode:pitch]; [audioNodes addObject:pitch];
        } else if (voiceType == 2) {
            AVAudioUnitTimePitch *pitch = [[AVAudioUnitTimePitch alloc] init];
            pitch.pitch = -800.0; [engine attachNode:pitch]; [audioNodes addObject:pitch];
        } else if (voiceType == 3) {
            AVAudioUnitReverb *reverb = [[AVAudioUnitReverb alloc] init];
            [reverb loadFactoryPreset:AVAudioUnitReverbPresetLargeHall];
            reverb.wetDryMix = 50.0; [engine attachNode:reverb]; [audioNodes addObject:reverb];
        } else if (voiceType == 4) {
            AVAudioUnitDistortion *distortion = [[AVAudioUnitDistortion alloc] init];
            [distortion loadFactoryPreset:AVAudioUnitDistortionPresetSpeechRadioTower];
            distortion.wetDryMix = 70.0; [engine attachNode:distortion]; [audioNodes addObject:distortion];
        } else if (voiceType == 5) {
            AVAudioUnitTimePitch *pitch = [[AVAudioUnitTimePitch alloc] init];
            pitch.pitch = -1200.0; [engine attachNode:pitch]; [audioNodes addObject:pitch];
            AVAudioUnitReverb *reverb = [[AVAudioUnitReverb alloc] init];
            [reverb loadFactoryPreset:AVAudioUnitReverbPresetMediumChamber];
            reverb.wetDryMix = 40.0; [engine attachNode:reverb]; [audioNodes addObject:reverb];
        }
        
        AVAudioFormat *sourceFormat = sourceFile.processingFormat;
        AVAudioNode *previousNode = playerNode;
        
        for (AVAudioNode *node in audioNodes) {
            [engine connect:previousNode to:node format:sourceFormat];
            previousNode = node;
        }
        [engine connect:previousNode to:engine.mainMixerNode format:sourceFormat];
        
        // 🚨 核心修复 3：引擎渲染保持原采样率，防止崩溃！只强压成单声道。
        AVAudioFormat *monoBufferFormat = [[AVAudioFormat alloc] initStandardFormatWithSampleRate:sourceFormat.sampleRate channels:1];
        
        [engine enableManualRenderingMode:AVAudioEngineManualRenderingModeOffline
                                   format:monoBufferFormat
                        maximumFrameCount:4096
                                    error:&error];
        if (error) { [self fallbackExportAudio:sourceURL completion:completion]; return; }
        
        [engine startAndReturnError:&error];
        if (error) { [self fallbackExportAudio:sourceURL completion:completion]; return; }
        
        [playerNode scheduleFile:sourceFile atTime:nil completionHandler:nil];
        [playerNode play];
        
        NSString *outFileName = [NSString stringWithFormat:@"dyyy_fx_%@.m4a", [[NSUUID UUID] UUIDString]];
        NSString *outputPath = [NSTemporaryDirectory() stringByAppendingPathComponent:outFileName];
        NSURL *outputURL = [NSURL fileURLWithPath:outputPath];
        
        // 🌟 文件输出端：强行要求降维打击到 16000Hz
        NSDictionary *outputSettings = @{
            AVFormatIDKey: @(kAudioFormatMPEG4AAC),
            AVSampleRateKey: @(16000.0),  
            AVNumberOfChannelsKey: @(1), 
            AVEncoderBitRateKey: @(32000) 
        };
        
        AVAudioFile *outputFile = [[AVAudioFile alloc] initForWriting:outputURL 
                                                             settings:outputSettings 
                                                         commonFormat:monoBufferFormat.commonFormat 
                                                          interleaved:monoBufferFormat.isInterleaved 
                                                                error:&error];
        if (error || !outputFile) { [self fallbackExportAudio:sourceURL completion:completion]; return; }
        
        AVAudioPCMBuffer *buffer = [[AVAudioPCMBuffer alloc] initWithPCMFormat:monoBufferFormat frameCapacity:engine.manualRenderingMaximumFrameCount];
        
        while (YES) {
            AVAudioFrameCount framesToRender = buffer.frameCapacity;
            AVAudioEngineManualRenderingStatus status = [engine renderOffline:framesToRender toBuffer:buffer error:&error];
            
            if (status == AVAudioEngineManualRenderingStatusSuccess) {
                [outputFile writeFromBuffer:buffer error:&error];
                if (error) break;
            } else if (status == AVAudioEngineManualRenderingStatusInsufficientDataFromInputNode) {
                break; 
            } else if (status == AVAudioEngineManualRenderingStatusError) {
                break; 
            }
        }
        
        [playerNode stop];
        [engine stop];
        
        if (error) {
            [self fallbackExportAudio:sourceURL completion:completion];
        } else {
            if (completion) completion(outputPath, nil);
        }
    });
}

@end
