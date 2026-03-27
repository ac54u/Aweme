#
#  DYYY
#
#  Copyright (c) 2024 huami. All rights reserved.
#  Channel: @huamidev
#  Created on: 2024/10/04
#

-include Makefile.local

# 编译目标设置
TARGET = iphone:clang:14.5:14.0
ARCHS = arm64 arm64e

# 打包方案选择
ifeq ($(SCHEME),roothide)
    export THEOS_PACKAGE_SCHEME = roothide
else ifeq ($(SCHEME),rootless)
    export THEOS_PACKAGE_SCHEME = rootless
else
    unexport THEOS_PACKAGE_SCHEME
endif

# CI 环境自动优化
ifeq ($(GITHUB_ACTIONS),true)
    export INSTALL = 0
    export FINALPACKAGE = 1
endif

export DEBUG = 0
INSTALL_TARGET_PROCESSES = Aweme
GO_EASY_ON_ME = 1

include $(THEOS)/makefiles/common.mk

TWEAK_NAME = DYYY

# --- 核心修复：合并所有文件 ---
DYYY_FILES = DYYY.xm \
             DYYYFloatClearButton.xm \
             DYYYFloatSpeedButton.m \
             DYYYSettings.xm \
             DYYYABTestHook.xm \
             DYYYLongPressPanel.xm \
             DYYYSettingsHelper.m \
             DYYYImagePickerDelegate.m \
             DYYYBackupPickerDelegate.m \
             DYYYSettingViewController.m \
             DYYYBottomAlertView.m \
             DYYYCustomInputView.m \
             DYYYOptionsSelectionView.m \
             DYYYIconOptionsDialogView.m \
             DYYYAboutDialogView.m \
             DYYYKeywordListView.m \
             DYYYFilterSettingsView.m \
             DYYYConfirmCloseView.m \
             DYYYToast.m \
             DYYYManager.m \
             DYYYUtils.m \
             CityManager.m \
             AWMSafeDispatchTimer.m \
             DYYYAudioManager.m \
             DYYYVoiceViewController.m

# --- 核心修复：合并 CFLAGS 解决 cmath 找不到的问题 ---
# 1. -x objective-c++: 强制以 Obj-C++ 编译，解决 cmath 报错 [cite: 7, 15]
# 2. -fno-modules: 禁用模块化编译，这是 CI 环境最稳的方案 [cite: 14, 22]
# 3. -w: 屏蔽所有警告
DYYY_CFLAGS = -fobjc-arc -x objective-c++ -fno-modules -w -std=c++11

# --- 核心修复：合并 LDFLAGS ---
# 链接标准 C++ 库并设置弱链接
DYYY_LDFLAGS = -lc++ -weak_framework AVFAudio

# --- 核心修复：合并所有 FRAMEWORKS ---
# 必须包含语音助手和保存功能需要的所有框架
DYYY_FRAMEWORKS = UIKit Photos AVFoundation CoreGraphics CoreMedia CoreAudio

export THEOS_STRICT_LOGOS = 0
export LOGOS_DEFAULT_GENERATOR = internal

include $(THEOS_MAKE_PATH)/tweak.mk

# 设备 IP 设置
ifeq ($(shell whoami),huami)
    export THEOS_DEVICE_IP = 192.168.31.228
else
    export THEOS_DEVICE_IP = 192.168.15.105
endif
THEOS_DEVICE_PORT = 22

# 清理指令
clean::
	@echo -e "\033[31m==>\033[0m Cleaning packages…"
	@rm -rf .theos packages obj

# 打包后处理
after-package::
	@echo -e "\033[32m==>\033[0m Packaging complete."