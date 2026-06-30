# Changelog

## [2.2-9] — 2026-07-01

### Fixed

#### Critical
- **ABTest 配置重新加载逻辑 Bug** (`DYYYABTestHook.xm:14–15, 175–186`)
  - 移除 `dispatch_once`，改用 `s_hasEverLoaded` 布尔标志
  - 修复远程配置更新后 `loadLocalABTestConfig` 无法重新加载的问题
  - `cleanLocalABTestData` → `loadLocalABTestConfig` 现在每次调用都会正确响应 `s_needsConfigReload` 标志

- **NSFileManager Hook 范围过大** (`DYYY.xm:1674`)
  - `containsString:@"AWEIMRoot/attachment"` 改为路径组件精确匹配
  - 拆分 `dstPath` 为路径组件数组，匹配 `"attachment"` 组件且父目录以 `"AWEIMRoot"` 结尾
  - 避免误拦截非私信附件的文件移动操作

- **静态全局变量竞态条件** (`DYYY.xm:31, 470–537`)
  - 新增 `os_unfair_lock gGestureLock` 保护手势相关全局变量
  - `gStartY` / `gStartVal` / `gMode` / `gFeedCV` 的所有读写操作加锁
  - UIKit 调用前提前释放锁，避免死锁

- **远程配置 JSON Schema 校验** (`DYYYABTestHook.xm:246–292`)
  - 新增 `DYYYValidateRemoteConfigJSON()` 白名单校验函数
  - 顶层键仅允许: `mode` / `data` / `version` / `description`
  - `mode` 值仅允许: `patch` / `replace` / `dyyy_mode_replace`
  - `data` 子值类型仅允许: `NSString` / `NSNumber` / `NSArray` / `NSDictionary`
  - 拒绝包含未知键或非法类型的配置，防止恶意 JSON 注入
