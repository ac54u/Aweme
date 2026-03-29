#import "DYYYVoiceChanger.h"

@implementation DYYYVoiceChanger

// --- 供 Hook 调用的同步方法 ---
+ (BOOL)processAudioFileFrom:(NSString *)srcPath to:(NSString *)dstPath {
    // 1. 读取当前的变调参数
    float currentPitch = 1000.0; // 1000 = 萝莉音，-1000 = 大叔音
    
    __block BOOL processSuccess = NO;
    dispatch_semaphore_t semaphore = dispatch_semaphore_create(0);
    
    NSLog(@"[DYYYVoiceChanger] ⏳ 开始处理音频，准备阻塞当前线程...");
    
    [self processAudioAtPath:srcPath withPitch:currentPitch completion:^(NSString *outputPath, NSError *error) {
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
            } else {
                NSLog(@"[DYYYVoiceChanger] ❌ 移动最终文件失败: %@", moveError.localizedDescription);
            }
        }
        dispatch_semaphore_signal(semaphore);
    }];
    
    // 设置超时保护，防止死锁
    dispatch_semaphore_wait(semaphore, dispatch_time(DISPATCH_TIME_NOW, 10 * NSEC_PER_SEC));
    
    return processSuccess;
}

// --- 核心变声方法 (AVAudioEngine 离线渲染) ---
+ (void)processAudioAtPath:(NSString *)inputPath
                 withPitch:(float)pitchValue
                completion:(void(^)(NSString *outputPath, NSError *error))completion {
    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0), ^{
        
        NSURL *sourceURL = [NSURL fileURLWithPath:inputPath];
        NSError *error = nil;
        
        // 1. 读取源音频文件
        AVAudioFile *sourceFile = [[AVAudioFile alloc] initForReading:sourceURL error:&error];
        if (error) {
            if (completion) completion(nil, error);
            return;
        }
        
        // 2. 准备变声引擎组件
        AVAudioEngine *engine = [[AVAudioEngine alloc] init];
        AVAudioPlayerNode *playerNode = [[AVAudioPlayerNode alloc] init];
        AVAudioUnitTimePitch *pitchNode = [[AVAudioUnitTimePitch alloc] init];
        
        // 设置变调参数
        pitchNode.pitch = pitchValue; 
        
        [engine attachNode:playerNode];
        [engine attachNode:pitchNode];
        
        // 3. 连接节点 (Player -> Pitch -> MainMixer)
        // 注意：连接时使用源文件的处理格式
        AVAudioFormat *format = sourceFile.processingFormat;
        [engine connect:playerNode to:pitchNode format:format];
        [engine connect:pitchNode to:engine.mainMixerNode format:format];
        
        // 4. 配置引擎进入离线渲染模式 (Manual Rendering Mode)
        // 最大帧数通常设为 4096 即可
        [engine enableManualRenderingMode:AVAudioEngineManualRenderingModeOffline
                                   format:format
                        maximumFrameCount:4096
                                    error:&error];
        if (error) {
            if (completion) completion(nil, error);
            return;
        }
        
        // 5. 启动引擎并准备播放
        [engine startAndReturnError:&error];
        if (error) {
            if (completion) completion(nil, error);
            return;
        }
        [playerNode scheduleFile:sourceFile atTime:nil completionHandler:nil];
        [playerNode play];
        
        // 6. 准备输出文件
        NSString *tempDir = NSTemporaryDirectory();
        NSString *outFileName = [NSString stringWithFormat:@"dyyy_changed_%@.m4a", [[NSUUID UUID] UUIDString]];
        NSString *outputPath = [tempDir stringByAppendingPathComponent:outFileName];
        NSURL *outputURL = [NSURL fileURLWithPath:outputPath];
        
        // 设置输出格式为 m4a (AAC 编码)，参数尽量贴合抖音的设定
        NSDictionary *outputSettings = @{
            AVFormatIDKey: @(kAudioFormatMPEG4AAC),
            AVSampleRateKey: @(format.sampleRate),
            AVNumberOfChannelsKey: @(format.channelCount),
            AVEncoderBitRateKey: @(96000) // 96kbps 足够清晰且体积小
        };
        
        AVAudioFile *outputFile = [[AVAudioFile alloc] initForWriting:outputURL
                                                             settings:outputSettings
                                                         commonFormat:format.commonFormat
                                                          interleaved:format.isInterleaved
                                                                error:&error];
        if (error) {
            if (completion) completion(nil, error);
            return;
        }
        
        // 7. 核心：执行离线渲染循环
        AVAudioPCMBuffer *buffer = [[AVAudioPCMBuffer alloc] initWithPCMFormat:engine.manualRenderingFormat
                                                                 frameCapacity:engine.manualRenderingMaximumFrameCount];
        
        // 计算源文件的总长度，防止无限渲染
        AVAudioFramePosition length = sourceFile.length;
        
        while (engine.manualRenderingSampleTime < length) {
            AVAudioFrameCount framesToRender = (AVAudioFrameCount)MIN(buffer.frameCapacity, length - engine.manualRenderingSampleTime);
            AVAudioEngineManualRenderingStatus status = [engine renderOffline:framesToRender toBuffer:buffer error:&error];
            
            if (status == AVAudioEngineManualRenderingStatusSuccess) {
                // 成功渲染出一块 buffer，写入文件
                [outputFile writeFromBuffer:buffer error:&error];
                if (error) break;
            } else if (status == AVAudioEngineManualRenderingStatusError) {
                // 渲染出错
                break;
            } else if (status == AVAudioEngineManualRenderingStatusInsufficientDataFromInputNode) {
                // 没有数据了，渲染完成
                break;
            }
        }
        
        // 8. 清理战场，结束处理
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