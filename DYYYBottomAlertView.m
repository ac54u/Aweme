#import "DYYYBottomAlertView.h"
#import "AwemeHeaders.h"
#import "DYYYUtils.h"

@implementation DYYYBottomAlertView

static NSCache *DYYYBottomAlertImageCache(void) {
    static NSCache *cache = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        cache = [[NSCache alloc] init];
        cache.countLimit = 50;
    });
    return cache;
}

+ (UIViewController *)showAlertWithTitle:(NSString *)title
                                 message:(NSString *)message
                               avatarURL:(nullable NSString *)avatarURL
                        cancelButtonText:(nullable NSString *)cancelButtonText
                       confirmButtonText:(nullable NSString *)confirmButtonText
                            cancelAction:(DYYYAlertActionHandler)cancelAction
                             closeAction:(nullable DYYYAlertActionHandler)closeAction
                           confirmAction:(DYYYAlertActionHandler)confirmAction {
    AFDPrivacyHalfScreenViewController *vc = [NSClassFromString(@"AFDPrivacyHalfScreenViewController") new];

    if (!vc)
        return nil;

    if (cancelButtonText.length == 0) {
        cancelButtonText = @"取消";
    }

    if (confirmButtonText.length == 0) {
        confirmButtonText = @"确定";
    }

    UIImageView *imageView = nil;
    if (avatarURL.length > 0) {
        imageView = [[UIImageView alloc] initWithFrame:CGRectMake(0, 0, 60, 60)];
        imageView.translatesAutoresizingMaskIntoConstraints = NO;
        [imageView.widthAnchor constraintEqualToConstant:60].active = YES;
        [imageView.heightAnchor constraintEqualToConstant:60].active = YES;
        imageView.layer.cornerRadius = 30;
        imageView.contentMode = UIViewContentModeScaleAspectFill;
        imageView.layer.masksToBounds = YES;
        imageView.clipsToBounds = YES;

        // 设置默认占位图
        imageView.image = [UIImage imageNamed:@"AppIcon60x60"];

        // 异步加载网络图片
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
          NSCache *cache = DYYYBottomAlertImageCache();
          UIImage *cachedImage = [cache objectForKey:avatarURL];
          if (cachedImage) {
              dispatch_async(dispatch_get_main_queue(), ^{
                imageView.image = cachedImage;
              });
              return;
          }
          NSURL *imageURL = [NSURL URLWithString:avatarURL];
          NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:imageURL cachePolicy:NSURLRequestReturnCacheDataElseLoad timeoutInterval:10.0];
          dispatch_semaphore_t sema = dispatch_semaphore_create(0);
          __block NSData *imageData = nil;
          NSURLSessionDataTask *task = [[NSURLSession sharedSession] dataTaskWithRequest:request completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {
            imageData = data;
            dispatch_semaphore_signal(sema);
          }];
          [task resume];
          dispatch_semaphore_wait(sema, dispatch_time(DISPATCH_TIME_NOW, (int64_t)(15 * NSEC_PER_SEC)));
          if (imageData) {
              UIImage *image = [UIImage imageWithData:imageData];
              if (image) {
                  [cache setObject:image forKey:avatarURL];
                  dispatch_async(dispatch_get_main_queue(), ^{
                    imageView.image = image;
                  });
              }
          }
        });
    }

    DYYYAlertActionHandler wrappedCancelAction = ^{
      if (cancelAction)
          cancelAction();
    };

    DYYYAlertActionHandler wrappedCloseActionBlock = ^{
      if (closeAction) {
          closeAction();
      } else {
          wrappedCancelAction();
      }
    };

    DYYYAlertActionHandler wrappedConfirmAction = ^{
      if (confirmAction)
          confirmAction();
    };

    vc.closeButtonClickedBlock = wrappedCloseActionBlock;
    vc.slideDismissBlock = wrappedCloseActionBlock;
    vc.tapDismissBlock = wrappedCloseActionBlock;

    [vc configWithImageView:imageView
                     lockImage:nil
              defaultLockState:NO
                titleLabelText:title
              contentLabelText:message
          leftCancelButtonText:cancelButtonText
        rightConfirmButtonText:confirmButtonText
          rightBtnClickedBlock:wrappedConfirmAction
        leftButtonClickedBlock:wrappedCancelAction];

    if (avatarURL.length > 0) {
        [vc setCornerRadius:11];
        [vc setOnlyTopCornerClips:YES];
    } else {
        [vc setUseCardUIStyle:YES];
    }

    UIViewController *topVC = [DYYYUtils topView];
    if (topVC && [vc respondsToSelector:@selector(presentOnViewController:)] && ![topVC isBeingPresented] && ![topVC isBeingDismissed]) {
        [vc presentOnViewController:topVC];
    } else {
        return nil;
    }

    return vc;
}
@end