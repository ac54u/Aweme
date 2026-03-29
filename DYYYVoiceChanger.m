#import "DYYYVoiceChanger.h"

@implementation DYYYVoiceChanger

// --- 供 Hook 调用的同步方法 ---
+ (BOOL)processAudioFileFrom:(NSString *)srcPath to:(NSString *)dstPath {
    // 1. 读取当前的变调参数（这里为了演示先写死，后续你可以从 NSUserDefaults 你的设置界面里读）
    float currentPitch = 1000.0; // 默认测试萝莉音
    
    __block BOOL processSuccess = NO;
    
    // 2. 创建 GCD 信号量，将下面的异步变声操作转为同步阻塞
    dispatch_semaphore_t semaphore = dispatch_semaphore_create(0);
    
    NSLog(@"[DYYYVoiceChanger] ⏳ 开始处理音频，准备阻塞当前线程...");
    
    // 3. 调用你的核心变声方法
    [self processAudioAtPath:srcPath withPitch:currentPitch completion:^(NSString *outputPath, NSError *error) {
        if (error || !outputPath) {
            NSLog(@"[DYYYVoiceChanger] ❌ 变音核心处理失败: %@", error.localizedDescription);
            processSuccess = NO;
        } else {
            // 4. 处理成功，将变声后的文件移动到系统真正期望的 dstPath
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
        
        // 5. 释放信号量，通知外部可以继续往下走了
        dispatch_semaphore_signal(semaphore);
    }];
    
    // 6. 等待信号量。设置 10 秒超时，防止极端情况下变声引擎卡死导致整个抖音卡死
    dispatch_semaphore_wait(semaphore, dispatch_time(DISPATCH_TIME_NOW, 10 * NSEC_PER_SEC));
    
    return processSuccess;
}

// --- 核心变声方法 (AVAudioEngine 离线渲染占位) ---
+ (void)processAudioAtPath:(NSString *)inputPath
                 withPitch:(float)pitchValue
                completion:(void(^)(NSString *outputPath, NSError *error))completion {
    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0), ^{
        
        NSFileManager *fm = [NSFileManager defaultManager];
        if (![fm fileExistsAtPath:inputPath]) {
            NSError *err = [NSError errorWithDomain:@"DYYYError" code:404 userInfo:@{NSLocalizedDescriptionKey: @"源音频文件不存在"}];
            if (completion) completion(nil, err);
            return;
        }
        
        // 生成一个临时的输出路径
        NSString *tempDir = NSTemporaryDirectory();
        NSString *outFileName = [NSString stringWithFormat:@"dyyy_changed_%@.m4a", [[NSUUID UUID] UUIDString]];
        NSString *outputPath = [tempDir stringByAppendingPathComponent:outFileName];
        
        // =========================================================
        // 🚀 这里是你需要填入 AVAudioEngine 离线渲染 (Manual Rendering) 的地方
        // 目前为了跑通逻辑，这里依然做了一个单纯的 Copy 模拟处理成功
        // =========================================================
        NSError *copyError = nil;
        BOOL success = [fm copyItemAtPath:inputPath toPath:outputPath error:&copyError];
        
        if (success) {
            // 模拟一下处理耗时
            [NSThread sleepForTimeInterval:0.2];
            if (completion) completion(outputPath, nil);
        } else {
            if (completion) completion(nil, copyError);
        }
    });
}

@end