#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

// 🔴 上帝视角探针：防撤回专属提示
static void showAntiRevokeToast(NSString *msg) {
    dispatch_async(dispatch_get_main_queue(), ^{
        UIWindow *win = [UIApplication sharedApplication].windows.firstObject;
        if (!win) return;
        UILabel *toast = [[UILabel alloc] initWithFrame:CGRectMake(win.bounds.size.width/2 - 160, 100, 320, 80)];
        toast.backgroundColor = [UIColor colorWithRed:0.2 green:0.6 blue:1.0 alpha:0.95]; // 科技蓝
        toast.textColor = [UIColor whiteColor];
        toast.text = msg;
        toast.numberOfLines = 0;
        toast.textAlignment = NSTextAlignmentCenter;
        toast.layer.cornerRadius = 15;
        toast.clipsToBounds = YES;
        toast.font = [UIFont boldSystemFontOfSize:14];
        [win addSubview:toast];
        [UIView animateWithDuration:0.5 delay:3.5 options:0 animations:^{ toast.alpha = 0; } completion:^(BOOL f){ [toast removeFromSuperview]; }];
    });
}

static inline BOOL DYYYIsAntiRecallEnabled(void) {
    return [[NSUserDefaults standardUserDefaults] boolForKey:@"DYYYAntiRecall"];
}

static inline BOOL DYYYIsNoReadReceiptEnabled(void) {
    return [[NSUserDefaults standardUserDefaults] boolForKey:@"DYYYNoReadReceipt"];
}

// ==========================================
// 🛡️ 防线 1：拦截 TIMMessage 底层 SDK 状态变更
// ==========================================
%hook TIMMessage

- (void)setIsRevoked:(BOOL)revoked {
    if (!DYYYIsAntiRecallEnabled()) {
        %orig;
        return;
    }
    if (revoked) {
        %orig(NO);
        dispatch_async(dispatch_get_main_queue(), ^{
            showAntiRevokeToast(@"🛡️ 拦截到一条撤回指令！\n原消息已为您保留。");
        });
        return;
    }
    %orig;
}

- (BOOL)isRevoked {
    if (!DYYYIsAntiRecallEnabled()) {
        return %orig;
    }
    return NO;
}

%end


// ==========================================
// 🛡️ 防线 2：拦截 AWEIMMessage 业务层状态变更
// ==========================================
%hook AWEIMMessage

- (void)setRevoked:(BOOL)revoked {
    if (!DYYYIsAntiRecallEnabled()) {
        %orig;
        return;
    }
    if (revoked) {
        %orig(NO);
        dispatch_async(dispatch_get_main_queue(), ^{
            showAntiRevokeToast(@"🛡️ 拦截到业务层撤回指令！\n消息已保住！");
        });
        return;
    }
    %orig;
}

- (BOOL)revoked {
    if (!DYYYIsAntiRecallEnabled()) {
        return %orig;
    }
    return NO;
}

%end

// ==========================================
// 🛡️ 防线 3：拦截撤回通知
// ==========================================
static void installRevokeNotificationGuard(void) {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        NSArray *suspectedNames = @[
            @"messageRevoked",
            @"MessageRevoked",
            @"kTIMMessageRevoked",
            @"TMessageRevoked",
            @"TIMMessageRevoked",
        ];
        for (NSString *name in suspectedNames) {
            [[NSNotificationCenter defaultCenter] addObserverForName:name object:nil queue:[NSOperationQueue mainQueue] usingBlock:^(NSNotification *note) {
                if (DYYYIsAntiRecallEnabled()) {
                    showAntiRevokeToast(@"🛡️ 拦截到撤回通知！\n消息已保住！");
                }
            }];
        }
    });
}

// ==========================================
// 👻 私信已读不回
// ==========================================
static void installNoReadReceiptHooks(void) {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        if (!DYYYIsNoReadReceiptEnabled()) return;

        // Hook TIMMessage 级别可能的已读标记方法
        Class timMsgClass = NSClassFromString(@"TIMMessage");
        if (timMsgClass) {
            NSArray *readSels = @[@"setIsRead:", @"setReadStatus:", @"setMsgRead:", @"markAsRead", @"setHasRead:"];
            for (NSString *selName in readSels) {
                SEL sel = NSSelectorFromString(selName);
                Method m = class_getInstanceMethod(timMsgClass, sel);
                if (m) {
                    IMP origIMP = method_getImplementation(m);
                    IMP newIMP = imp_implementationWithBlock(^(id self) {
                        if (DYYYIsNoReadReceiptEnabled()) return;
                        ((void (*)(id, SEL))origIMP)(self, sel);
                    });
                    method_setImplementation(m, newIMP);
                }
            }
        }

        // Hook AWEIMMessage 级别的已读方法
        Class aweMsgClass = NSClassFromString(@"AWEIMMessage");
        if (aweMsgClass) {
            NSArray *readSels = @[@"setIsRead:", @"setRead:", @"markRead", @"setMsgRead:"];
            for (NSString *selName in readSels) {
                SEL sel = NSSelectorFromString(selName);
                Method m = class_getInstanceMethod(aweMsgClass, sel);
                if (m) {
                    IMP origIMP = method_getImplementation(m);
                    IMP newIMP = imp_implementationWithBlock(^(id self) {
                        if (DYYYIsNoReadReceiptEnabled()) return;
                        ((void (*)(id, SEL))origIMP)(self, sel);
                    });
                    method_setImplementation(m, newIMP);
                }
            }
        }

        // Hook 会话级别的已读上报
        Class convClass = NSClassFromString(@"AWEIMConversation");
        if (!convClass) convClass = NSClassFromString(@"TIMConversation");
        if (convClass) {
            NSArray *convSels = @[@"markAllMessagesAsRead", @"reportReaded", @"setAllMessagesRead", @"readMessages:"];
            for (NSString *selName in convSels) {
                SEL sel = NSSelectorFromString(selName);
                Method m = class_getInstanceMethod(convClass, sel);
                if (m) {
                    IMP origIMP = method_getImplementation(m);
                    IMP newIMP = imp_implementationWithBlock(^(id self) {
                        if (DYYYIsNoReadReceiptEnabled()) return;
                        ((void (*)(id, SEL))origIMP)(self, sel);
                    });
                    method_setImplementation(m, newIMP);
                }
            }
        }
    });
}

%ctor {
    %init;

    // 在下一个 runloop 周期安装动态 Hook（此时所有类已加载）
    dispatch_async(dispatch_get_main_queue(), ^{
        installRevokeNotificationGuard();
        installNoReadReceiptHooks();
    });
}
