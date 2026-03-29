#import <Foundation/Foundation.h>
#import <AVFoundation/AVFoundation.h>

@interface DYYYVoiceChanger : NSObject

// --------------------------------------------------
// 🔗 桥接方法：供 NSFileManager Hook 同步调用
// --------------------------------------------------
+ (BOOL)processAudioFileFrom:(NSString *)srcPath to:(NSString *)dstPath;

// --------------------------------------------------
// 🎛️ 核心变声方法：输入原路径 -> 变调 -> 输出新路径
// --------------------------------------------------
+ (void)processAudioAtPath:(NSString *)inputPath
                 withPitch:(float)pitchValue // 1000 是萝莉，-1000 是大叔
                completion:(void(^)(NSString *outputPath, NSError *error))completion;

@end