#ifndef DYYYConstants_h
#define DYYYConstants_h

#define DYYY_NAME @"DYYY"
#define DYYY_SETTINGS_NAME @"DYYY设置"

#define DYYY_VERSION @"2.2-8"

// 默认的远程 ABTest 配置地址
#define DYYY_DEFAULT_ABTEST_URL @"https://github.com/Nathalie-Annis/AWEABTestDataPatch/releases/latest/download/ABTestDataPatch_A.json"

// 是否使用远程配置的偏好键
#define DYYY_REMOTE_CONFIG_FLAG_KEY @"DYYYUseRemoteConfig"

// 远程配置状态改变的通知名
#define DYYY_REMOTE_CONFIG_CHANGED_NOTIFICATION @"DYYYRemoteConfigStateChanged"

// 配置应用方式中的远程模式名称
#define DYYY_REMOTE_MODE_STRING @"远程模式：启动时自动检查更新"

#define DYYYGeonamesErrorDomain @"com.dyyy.geonames.api.error"
#define DYYYGeonamesStatusUserInfoKey @"com.dyyy.geonames.api.status"

#define DYYY_IGNORE_GLOBAL_ALPHA_TAG 114514
#define DYYY_CLEAR_BUTTON_TAG 232323
#define DYYY_DEFAULT_SPEED_BUTTON_SIZE 32.0f
#define DYYY_DEFAULT_CLEAR_BUTTON_SIZE 40.0f
#define DYYY_MAX_AUDIO_FILE_SIZE (50 * 1024 * 1024)
#define DYYY_AUDIO_MAX_DURATION 29.5f
#define DYYY_DOWNLOAD_TIMEOUT 60.0f

#endif
