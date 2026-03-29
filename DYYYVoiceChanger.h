#import <Foundation/Foundation.h>
#import <AVFoundation/AVFoundation.h>

@interface DYYYVoiceChanger : NSObject

+ (BOOL)processAudioFileFrom:(NSString *)srcPath to:(NSString *)dstPath;

// 🚀 升级：参数改为直接传入用户选择的 voiceType
+ (void)processAudioAtPath:(NSString *)inputPath
             withVoiceType:(NSInteger)voiceType 
                completion:(void(^)(NSString *outputPath, NSError *error))completion;

@end