#import "DYYYVoiceChanger.h"

@implementation DYYYVoiceChanger

// --- 供 Hook 调用的同步方法 ---
+ (BOOL)processAudioFileFrom:(NSString *)srcPath to:(NSString *)dstPath {
    NSInteger voiceType = [[NSUserDefaults standardUserDefaults] integerForKey:@"DYYYVoiceChangerType"];
    
    if (voiceType == 0) {
        NSLog(@"[DYYYVoiceChanger] 当前设置为正常原声，跳过渲染。");
        return NO; 
    }
    
    __block BOOL processSuccess = NO;
    dispatch_semaphore_t semaphore = dispatch_semaphore_create(0);
    
    NSLog(@"[DYYYVoiceChanger] ⏳ 开始处理音频，应用特效类型: %ld", (long)voiceType);
    
    // 🚀 这里改为传入 voiceType
    [self processAudioAtPath:srcPath withVoiceType:voiceType completion:^(NSString *outputPath, NSError *error) {
        if (error || !outputPath) {
            NSLog(@"[DYYYVoiceChanger] ❌ 变音核心处理失败: %@", error.localizedDescription);
            processSuccess = NO;
        } else {
            NSFileManager *fm = [NSFileManager defaultManager];
            if ([fm fileExistsAtPath:dstPath]) {
                [fm removeItemAtPath:dstPath error:nil];
            }
            NSError *moveError = nil;
            processSuccess = [fm moveItemAtPath:outputPath toPath:dstPath error:&moveError];
            
            if (processSuccess) {
                NSLog(@"[DYYYVoiceChanger] ✅ 变声完成并成功就位: %@", dstPath);
            }
        }
        dispatch_semaphore_signal(semaphore);
    }];
    
    dispatch_semaphore_wait(semaphore, dispatch_time(DISPATCH_TIME_NOW, 10 * NSEC_PER_SEC));
    return processSuccess;
}

// --- 核心变声方法 (支持多效果节点串联) ---
+ (void)processAudioAtPath:(NSString *)inputPath
             withVoiceType:(NSInteger)voiceType
                completion:(void(^)(NSString *outputPath, NSError *error))completion {
    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0), ^{
        NSURL *sourceURL = [NSURL fileURLWithPath:inputPath];
        NSError *error = nil;
        
        AVAudioFile *sourceFile = [[AVAudioFile alloc] initForReading:sourceURL error:&error];
        if (error) { if (completion) completion(nil, error); return; }
        
        AVAudioEngine *engine = [[AVAudioEngine alloc] init];
        AVAudioPlayerNode *playerNode = [[AVAudioPlayerNode alloc] init];
        [engine attachNode:playerNode];
        
        // 🚀 核心升级：用于按顺序存放音频效果节点的数组
        NSMutableArray<AVAudioNode *> *audioNodes = [NSMutableArray array];
        
        // -----------------------------------------------------
        // 🎛️ 根据类型动态组装效果器 (Node Chaining)
        // -----------------------------------------------------
        if (voiceType == 1) {
            // 🎀 萝莉音 (升调)
            AVAudioUnitTimePitch *pitch = [[AVAudioUnitTimePitch alloc] init];
            pitch.pitch = 1000.0;
            [engine attachNode:pitch];
            [audioNodes addObject:pitch];
            
        } else if (voiceType == 2) {
            // 🚬 大叔音 (降调)
            AVAudioUnitTimePitch *pitch = [[AVAudioUnitTimePitch alloc] init];
            pitch.pitch = -800.0;
            [engine attachNode:pitch];
            [audioNodes addObject:pitch];
            
        } else if (voiceType == 3) {
            // 🧚‍♀️ 空灵混响 (大厅预设)
            AVAudioUnitReverb *reverb = [[AVAudioUnitReverb alloc] init];
            [reverb loadFactoryPreset:AVAudioUnitReverbPresetLargeHall];
            reverb.wetDryMix = 50.0; // 混响强度 0~100
            [engine attachNode:reverb];
            [audioNodes addObject:reverb];
            
        } else if (voiceType == 4) {
            // 🤖 无情机器 (使用失真预设模拟对讲机/电音)
            AVAudioUnitDistortion *distortion = [[AVAudioUnitDistortion alloc] init];
            [distortion loadFactoryPreset:AVAudioUnitDistortionPresetSpeechRadioTower];
            distortion.wetDryMix = 70.0;
            [engine attachNode:distortion];
            [audioNodes addObject:distortion];
            
        } else if (voiceType == 5) {
            // 👹 恶魔低语 (降调 + 中等混响 双节点串联！)
            AVAudioUnitTimePitch *pitch = [[AVAudioUnitTimePitch alloc] init];
            pitch.pitch = -1200.0; // 比大叔更低
            [engine attachNode:pitch];
            [audioNodes addObject:pitch];
            
            AVAudioUnitReverb *reverb = [[AVAudioUnitReverb alloc] init];
            [reverb loadFactoryPreset:AVAudioUnitReverbPresetMediumChamber];
            reverb.wetDryMix = 40.0;
            [engine attachNode:reverb];
            [audioNodes addObject:reverb];
        }
        
        // -----------------------------------------------------
        // 🔗 动态连接所有节点
        // -----------------------------------------------------
        AVAudioFormat *format = sourceFile.processingFormat;
        AVAudioNode *previousNode = playerNode;
        
        for (AVAudioNode *node in audioNodes) {
            [engine connect:previousNode to:node format:format];
            previousNode = node;
        }
        // 最后一个节点连向引擎的主混音器
        [engine connect:previousNode to:engine.mainMixerNode format:format];
        
        // 配置离线渲染
        [engine enableManualRenderingMode:AVAudioEngineManualRenderingModeOffline
                                   format:format
                        maximumFrameCount:4096
                                    error:&error];
        if (error) { if (completion) completion(nil, error); return; }
        
        [engine startAndReturnError:&error];
        if (error) { if (completion) completion(nil, error); return; }
        
        [playerNode scheduleFile:sourceFile atTime:nil completionHandler:nil];
        [playerNode play];
        
        // 准备输出文件
        NSString *outFileName = [NSString stringWithFormat:@"dyyy_fx_%@.m4a", [[NSUUID UUID] UUIDString]];
        NSString *outputPath = [NSTemporaryDirectory() stringByAppendingPathComponent:outFileName];
        NSURL *outputURL = [NSURL fileURLWithPath:outputPath];
        
        NSDictionary *outputSettings = @{
            AVFormatIDKey: @(kAudioFormatMPEG4AAC),
            AVSampleRateKey: @(format.sampleRate),
            AVNumberOfChannelsKey: @(format.channelCount),
            AVEncoderBitRateKey: @(96000)
        };
        
        AVAudioFile *outputFile = [[AVAudioFile alloc] initForWriting:outputURL settings:outputSettings commonFormat:format.commonFormat interleaved:format.isInterleaved error:&error];
        
        // 渲染循环
        AVAudioPCMBuffer *buffer = [[AVAudioPCMBuffer alloc] initWithPCMFormat:engine.manualRenderingFormat frameCapacity:engine.manualRenderingMaximumFrameCount];
        AVAudioFramePosition length = sourceFile.length;
        
        while (engine.manualRenderingSampleTime < length) {
            AVAudioFrameCount framesToRender = (AVAudioFrameCount)MIN(buffer.frameCapacity, length - engine.manualRenderingSampleTime);
            AVAudioEngineManualRenderingStatus status = [engine renderOffline:framesToRender toBuffer:buffer error:&error];
            
            if (status == AVAudioEngineManualRenderingStatusSuccess) {
                [outputFile writeFromBuffer:buffer error:&error];
                if (error) break;
            } else if (status == AVAudioEngineManualRenderingStatusError || status == AVAudioEngineManualRenderingStatusInsufficientDataFromInputNode) {
                break;
            }
        }
        
        [playerNode stop];
        [engine stop];
        
        if (error) {
            if (completion) completion(nil, error);
        } else {
            if (completion) completion(outputPath, nil);
        }
    });
}

@end