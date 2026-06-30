# DYYY

> 抖音（com.ss.iphone.ugc.Aweme）iOS 越狱增强插件 —— 提供视频下载、UI 定制、隐私保护、直播隐身、私信变声等 200+ 项功能，全部可在应用内实时开关。

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](./LICENSE)
[![Version](https://img.shields.io/badge/Version-2.2--8-blue)]()
[![Platform](https://img.shields.io/badge/Platform-iOS%2FiPadOS-lightgrey)]()

---

## 目录

- [为什么会有这个项目](#为什么会有这个项目)
- [前置条件](#前置条件)
- [编译构建](#编译构建)
- [安装方式](#安装方式)
- [如何进入设置面板](#如何进入设置面板)
- [功能列表](#功能列表)
  - [视频播放与画质](#1-视频播放与画质)
  - [下载与资源管理](#2-下载与资源管理)
  - [UI 定制与界面净化](#3-ui-定制与界面净化)
  - [频道管理与顶栏移除](#4-频道管理与顶栏移除)
  - [长按面板与双击手势](#5-长按面板与双击手势)
  - [评论、弹幕与通知](#6-评论弹幕与通知)
  - [直播模式](#7-直播模式)
  - [隐私与埋点拦截](#8-隐私与埋点拦截)
  - [IM 私信增强（防撤回 + 变声器）](#9-im-私信增强)
  - [iPad 横屏适配](#10-ipad-横屏适配)
- [远程配置（ABTest）](#远程配置abtest)
- [API 解析下载接口](#api-解析下载接口)
- [音频助手与语音收藏夹](#音频助手与语音收藏夹)
- [私信变声器](#私信变声器)
- [版本兼容性说明](#版本兼容性说明)
- [常见问题（FAQ）](#常见问题faq)
- [贡献指南](#贡献指南)
- [更新日志](#更新日志)
- [许可证](#许可证)

---

## 为什么会有这个项目

抖音 iOS 客户端内置了大量运营元素、埋点上报和行为限制，很多功能在官方应用中不存在或不开放。DYYY 通过 Theos/Logos 框架在运行时 Hook 抖音的私有 API，将一系列实用功能注入到原版 App 中，让你在不修改 App 二进制文件的前提下，获得一个更干净、更强大、更隐私友好的抖音客户端。

**核心痛点解决**：

- 视频/图片/音频无法直接保存到相册 → **支持多格式下载**
- 推荐流充满广告和低质内容 → **可选过滤规则 + 频道移除**
- 浏览他人主页会留下记录 → **无痕浏览模式，拦截埋点**
- 私信语音无法变声 → **内置 5 种实时变声效果**
- iPad 版抖音界面丑陋 → **横屏适配 + UI 元素缩放**

---

## 前置条件

在构建和使用 DYYY 之前，请确保你满足以下条件：

| 要求 | 说明 |
|------|------|
| **越狱设备** | iPhone 或 iPad，已通过 Dopamine、palera1n、unc0ver 等工具完成越狱 |
| **iOS/iPadOS 14.0+** | 本项目的部署目标为 iOS 14.0 |
| **Theos 开发环境** | 用于编译 Tweak 为 .deb 包（仅开发者需要） |
| **抖音 35.1.0** | 目前仅在 **抖音 35.1.0 版本** 上测试通过，不保证其他版本兼容 |
| **基础依赖** | mobilesubstrate、firmware (>= 5.0) —— 安装 .deb 时自动检查 |
| **SSH 访问** | 通过 USB 或 Wi-Fi SSH 连接到越狱设备（用于安装和调试） |

> **提示**：如果你只是安装使用，直接下载预编译的 .deb 包并通过 Sileo / Zebra / SSH 安装即可，无需搭建 Theos 环境。

---

## 编译构建

### 1. 搭建 Theos 环境

在 macOS / Linux (WSL) 上安装 Theos：

```bash
# 安装 Theos（如果尚未安装）
export THEOS=/opt/theos
git clone --recursive https://github.com/theos/theos.git $THEOS

# 确保已安装 Xcode 命令行工具（macOS）或 clang 工具链（Linux）
xcode-select --install   # macOS
```

### 2. 配置设备连接

在项目根目录创建 `Makefile.local`（该文件已被 `.gitignore` 忽略）：

```makefile
export THEOS_DEVICE_IP = 192.168.x.x
THEOS_DEVICE_PORT = 22
```

> **注意**：确保设备 SSH 已开放（默认端口 22）。可通过 USB 映射端口或 Wi-Fi 局域网连接。

### 3. 编译

```bash
cd /path/to/Aweme

# 普通编译（Rootful 越狱）
make package

# Rootless 越狱（如 Dopamine）
make package SCHEME=rootless

# RootHide 越狱
make package SCHEME=roothide

# 一键编译并安装到设备
make package install
```

编译产物位于 `packages/` 目录下，为 `.deb` 格式的安装包。

### 4. 编译选项说明

| 变量 | 说明 |
|------|------|
| `SCHEME=rootless` | 生成适用于 Rootless 越狱的 deb 包 |
| `SCHEME=roothide` | 生成适用于 RootHide 环境的 deb 包 |
| `DEBUG=0` | 当前默认关闭调试模式 |
| `GITHUB_ACTIONS=true` | CI 环境自动跳过设备安装步骤 |

> **CI/CD**：项目已配置 GitHub Actions 自动编译工作流（`.github/` 目录下），每次推送会自动生成 `.deb` 包。

---

## 安装方式

### 方式一：通过包管理器安装（推荐）

将 `.deb` 文件导入 Sileo / Zebra / Cydia，直接点击安装。安装完成后打开抖音即可生效。

### 方式二：通过 SSH 手动安装

```bash
# 将 deb 包上传到设备并安装
scp packages/com.xiaopan.dyyy_*.deb root@设备IP:/tmp/
ssh root@设备IP "dpkg -i --force-overwrite /tmp/com.xiaopan.dyyy_*.deb && rm -f /tmp/com.xiaopan.dyyy_*.deb"

# 重启抖音（或 Respring）
ssh root@设备IP "killall Aweme"
```

### 方式三：使用 Filza 安装

将 `.deb` 文件通过 AirDrop / 文件 App 传输到设备，使用 Filza 打开并点击「安装」按钮。

---

## 如何进入设置面板

DYYY 提供两种方式进入设置界面：

### 1. 双指长按（任意界面可用）

在抖音任意界面使用 **两根手指同时长按屏幕**（约 0.5 秒），即可弹出 DYYY 设置面板。这是最便捷的入口。

- iPhone：以 `UIModalPresentationPageSheet` 形式展示（半屏弹出）
- iPad：以 `UIModalPresentationFullScreen` 形式展示（全屏 + 关闭按钮）

### 2. 通过抖音自带设置

在抖音「我 → 右上角菜单 → 设置」页面中，DYYY 会自动注入「DYYY 设置」入口，点击即可进入。

### 设置面板结构

设置面板分为 **8 个分组**（每个分组可折叠/展开）：

| 分组 | 名称 | 内容 |
|------|------|------|
| 第 1 组 | 基本设置 | 视频背景色、弹幕颜色、倍速、进度条、画质、直播画质、PCDN 等 |
| 第 2 组 | 界面设置 | 全局透明度、元素缩放、偏移量、底栏高度、TabBar 标题修改 |
| 第 3 组 | 隐藏设置 | 60+ 项 UI 元素隐藏开关（底栏、侧栏、按钮、标签等） |
| 第 4 组 | 顶栏移除 | 15 个频道选项卡的显示/隐藏（推荐、关注、商城、同城等） |
| 第 5 组 | 隐藏面板 | 长按面板和评论面板中指定选项的显示/隐藏 |
| 第 6 组 | 面板设置 | 长按面板和双击面板的功能开关（下载、复制、过滤等） |
| 第 7 组 | 功能设置 | 接口解析、双击行为、评论增强、表情包保存等 |
| 第 8 组 | 悬浮按钮 | 快捷倍速按钮和一键清屏按钮的配置 |

---

## 功能列表

DYYY 功能按 DYYY.xm 中的分区组织，覆盖 15 个大类。以下列出每个类别中的核心功能：

### 1. 视频播放与画质

| 功能 | 说明 | 设置键 |
|------|------|--------|
| **强制最高画质** | 自动选择比特率最高的视频流播放 | `DYYYEnableVideoHighestQuality` |
| **默认播放倍速** | 全局设定默认倍速（0.75x ~ 3.0x） | `DYYYDefaultSpeed` |
| **长按倍速** | 长按屏幕时切换到的倍速 | `DYYYLongPressSpeed` |
| **上下滑动控制倍速** | 在视频上上下滑动手势切换倍速 | `DYYYEnableLongPressSpeedGesture` |
| **快捷倍速悬浮按钮** | 屏幕边缘拖拽式倍速切换按钮 | `DYYYEnableFloatSpeedButton` |
| **自动恢复默认倍速** | 切换视频时自动回到默认倍速 | `DYYYAutoRestoreSpeed` |
| **显示进度时长** | 视频进度条两侧显示当前时间/总时长标签 | `DYYYShowScheduleDisplay` |
| **进度纵轴偏移** | 自定义进度条垂直位置 | `DYYYTimelineVerticalPosition` |
| **视频背景颜色** | 自定义视频黑边背景色（十六进制） | `DYYYVideoBGColor` |
| **首页全屏模式** | 视频扩展至整个屏幕（覆盖底栏） | `DYYYEnableFullScreen` |
| **后台播放** | 退出 App 后继续播放视频声音 | `DYYYEnableBackgroundListen` |
| **自动连播** | 当前视频结束后自动播放下一个 | `DYYYEnableAutoPlay` |
| **禁用双击点赞** | 关闭双击视频自动点赞 | `DYYYDisableDoubleTapLike` |
| **禁用首页刷新** | 点击首页 Tab 不再触发刷新 | `DYYYDisableHomeRefresh` |

### 2. 下载与资源管理

| 功能 | 说明 | 设置键 |
|------|------|--------|
| **保存视频** | 将当前播放的视频保存到相册 | 通过长按/双击面板触发 |
| **保存封面** | 将视频封面图保存到相册 | `DYYYLongPressSaveCover` |
| **保存音频** | 提取视频的背景音乐保存 | `DYYYLongPressSaveAudio` |
| **保存当前图片** | 图文模式下保存当前查看的图片 | `DYYYLongPressSaveCurrentImage` |
| **保存所有图片** | 图文模式下批量保存全部图片 | `DYYYLongPressSaveAllImages` |
| **保存实况照片** | 支持保存 Live Photo 格式 | 自动检测 |
| **批量下载** | 带进度条的批量资源下载 | — |
| **取消所有下载** | 一键取消所有进行中的下载任务 | — |
| **下载完成震动反馈** | 下载完成后触发 Haptic 震动 | `DYYYHapticFeedbackEnabled` |
| **保存评论区图片** | 保存评论中不带水印的图片和实况照 | `DYYYCommentNotWaterMark` |
| **保存表情包** | 保存评论区/预览页/聊天页的动图表情 | `DYYYForceDownloadEmotion` 系列 |
| **保存他人头像** | 在他人主页长按保存头像 | `DYYYEnableSaveAvatar` |
| **接口解析下载** | 通过自定义 API 接口解析并下载资源（见下方详细说明） | `DYYYInterfaceDownload` |

### 3. UI 定制与界面净化

DYYY 提供 **极其丰富的 UI 隐藏/显示选项**：

**底栏（TabBar）定制：**
- 修改底栏高度
- 隐藏商城、消息、朋友、我的、加号按钮
- 自定义首页/朋友/消息/我的标签文字
- 隐藏底栏评论输入框、红点、背景、热搜榜

**播放页界面净化：**
- 隐藏点赞/评论/收藏/分享按钮及其数值
- 隐藏头像按钮、音乐按钮、分享按钮
- 隐藏视频定位标签、合拍创作者头像
- 隐藏弹幕按钮、取消静音按钮、「去汽水听」按钮
- 隐藏暂停时显示的相关视频、锚点链接
- 隐藏「上次看到这」「展开更多」渐变
- 隐藏进度滑条（视频/图片）

**全局/系统级：**
- 全局透明度覆盖（0.0 ~ 1.0）
- 顶栏透明度控制
- 首页头像透明度
- 昵称/描述/IP 标签缩放和偏移
- 右侧 UI 元素缩放
- 隐藏系统状态栏
- 应用内通知毛玻璃效果 + 圆角半径
- 评论区和 ActionSheet 毛玻璃效果
- 隐藏青少年模式弹窗
- 屏蔽开屏广告和视频广告
- 屏蔽版本更新检测和红点

**侧边栏：**
- 隐藏整个左侧边栏
- 隐藏常用小程序、常访问的人
- 隐藏侧栏红点、天气标签
- 自定义快捷入口

### 4. 频道管理与顶栏移除

可单独移除或隐藏抖音顶部的 **15 个频道标签**：

| 频道名 | 频道 ID | 设置键 |
|--------|---------|--------|
| 推荐 | `homepage_hot_container` | `DYYYHideHotContainer` |
| 关注 | `homepage_follow` | `DYYYHideFollow` |
| 商城 | `homepage_mall` | `DYYYHideMall` |
| 同城 | `homepage_nearby` | `DYYYHideNearby` |
| 团购 | `homepage_groupon` | `DYYYHideGroupon` |
| 直播 | `homepage_tablive` | `DYYYHideTabLive` |
| 热点 | `homepage_pad_hot` | `DYYYHidePadHot` |
| 经验 | `homepage_hangout` | `DYYYHideHangout` |
| 朋友 | `homepage_familiar` | `DYYYHideFriend` |
| 短剧 | `homepage_playlet_stream` | `DYYYHidePlaylet` |
| 看剧 | `homepage_pad_cinema` | `DYYYHideCinema` |
| 少儿 | `homepage_pad_kids_v2` | `DYYYHideKidsV2` |
| 游戏 | `homepage_pad_game` | `DYYYHideGame` |
| 精选 | `homepage_mediumvideo` | `DYYYHideMediumVideo` |

### 5. 长按面板与双击手势

**长按面板（视频/图片长按弹出菜单）：**

- 启用新版 Modern 长按面板 UI
- 面板毛玻璃效果 + 深色模式
- 添加自定义功能入口：保存视频、保存封面、保存音频、保存当前图片、保存所有图片
- 添加 API 接口解析下载入口
- 复制视频文案 / 复制分享链接
- 过滤指定用户的所有视频
- 过滤指定关键词的视频标题
- 定时关闭（到时间自动停止播放）
- 从图片生成视频
- 语音收藏夹入口
- 隐藏原面板中不需要的选项（日常、推荐、举报、倍速、清屏、缓存、投屏、弹幕、识图、听抖音、稍后再看、自动连播、不感兴趣、后台播放、定时关闭等 17 项）

**双击手势：**

- 双击打开下载/操作面板
- 双击直接保存视频/音频
- 双击接口解析下载
- 双击生成视频
- 双击复制文案
- 双击直接打开评论区
- 双击点赞 / 分享 / 不感兴趣

### 6. 评论、弹幕与通知

**弹幕功能：**
- 全局启用弹幕改色
- 自定义弹幕颜色（十六进制）
- 七彩旋转弹幕颜色
- 清屏时自动隐藏弹幕

**评论区增强：**
- 评论区毛玻璃模糊背景
- 长按评论一键复制评论文本
- 移除评论图片水印
- 评论自动勾选原图发送
- 隐藏评论相关的搜索、分享等菜单项

**通知样式：**
- 应用内通知毛玻璃效果（跟随深色/浅色模式）
- 通知圆角半径自定义
- 隐藏通知横幅

### 7. 直播模式

| 功能 | 说明 | 设置键 |
|------|------|--------|
| **全局隐身模式** | 进入任何直播间不显示进场动效、不暴露在线状态 | `DYYYLiveGhostMode` |
| **直播默认画质** | 自动选择指定清晰度（蓝光帧彩/蓝光/超清/高清/标清） | `DYYYLiveQuality` |
| **禁用直播 PCDN** | 阻止 PCDN 上传（节省流量和电量） | `DYYYDisableLivePCDN` |
| **禁用自动进入直播** | 刷推荐流时防止误触自动进入直播间 | `DYYYDisableAutoEnterLive` |
| **直播 UI 隐藏** | 隐藏直播间关闭按钮、横屏按钮、返回按钮、商品信息、点赞动画、投屏按钮等 | 多项设置键 |

### 8. 隐私与埋点拦截

**无痕浏览模式：**

拦截字节跳动底层埋点 SDK（`BDTrackerProtocol` 和 `Tracker`），阻止以下事件上报：

- `enter_personal_detail` — 进入他人主页
- `profile_pv` — 增加主页浏览量
- `others_homepage` — 他人主页互动
- `visit_profile` — 访问主页

> 拦截只针对浏览行为，点赞、评论等正常互动事件的埋点 **不会被拦截**（避免触发风控）。

### 9. IM 私信增强

**防撤回（双重拦截）：**

- 第一道防线：Hook `TIMMessage` 层，拦截 `setIsRevoked` 和 `isRevoked`
- 第二道防线：Hook `AWEIMMessage` 业务层，拦截 `setRevoked` 和 `revoked`
- 当对方撤回消息时，DYYY 会 **保留原消息** 并在屏幕顶部弹出拦截提示

**私信变声器：**

Hook 私信语音发送流程，在文件写入磁盘前替换为变声后的音频。详见 [私信变声器](#私信变声器) 章节。

### 10. iPad 横屏适配

- iPad 布局适配（全屏设置面板、关闭按钮）
- UI 元素在横屏模式下的位置和缩放调整

---

## 远程配置（ABTest）

DYYY 支持通过远程 JSON 配置文件批量下发设置，无需重新安装或手动逐项修改。这对批量部署或多设备同步非常有用。

### 默认配置地址

远程配置的默认下载地址定义在 `DYYYConstants.h` 中：

```objc
#define DYYY_DEFAULT_ABTEST_URL @"https://github.com/Nathalie-Annis/AWEABTestDataPatch/releases/latest/download/ABTestDataPatch_A.json"
```

### 配置文件格式

```json
{
    "mode": "patch",
    "version": "1.0",
    "description": "我的DYYY配置",
    "data": {
        "DYYYEnableVideoHighestQuality": true,
        "DYYYDefaultSpeed": 2.0,
        "DYYYNoAds": true,
        "DYYYLiveGhostMode": true,
        "DYYYGlobalTransparency": "0.85"
    }
}
```

### 字段说明

| 字段 | 类型 | 必填 | 说明 |
|------|------|------|------|
| `mode` | `string` | 否 | 配置模式：`"patch"`（补丁模式，仅更新 data 中的项）或 `"replace"`（替换模式，完全覆盖本地设置）。省略时默认为 `"patch"` |
| `version` | `string` | 否 | 配置文件版本号，仅供记录 |
| `description` | `string` | 否 | 配置描述 |
| `data` | `object` | 是 | 键值对集合。键为设置项名称（与设置面板中的 key 一致），值仅允许 `string` / `number` / `boolean` / `array` / `object` 类型 |

### 安全校验

v2.2-9 起，DYYY 内置了 JSON Schema 白名单校验函数 `DYYYValidateRemoteConfigJSON()`：
- 顶层键仅允许：`mode` / `data` / `version` / `description`
- `mode` 值仅允许：`"patch"` / `"replace"` / `"dyyy_mode_replace"`
- **拒绝包含未知键或非法类型的配置**，防止恶意 JSON 注入恶意设置

### 使用方式

进入 DYYY 设置面板，在「功能设置」分区中切换远程配置模式：
- **远程模式：启动时自动检查更新** — 每次打开抖音自动拉取最新配置
- **替换模式：忽略原配置，使用新数据** — 从 JSON 文件完全覆盖
- 应用范围选择「仅项目配置进入时使用」或「远程模式」

---

## API 解析下载接口

DYYY 支持通过自定义 API 接口解析并下载视频、图片、音频资源。配置方式：在设置面板中填写 API 接口地址到 `DYYYInterfaceDownload` 字段，然后通过长按面板或双击面板中的「接口解析」选项触发下载。

以下是 API 返回数据的 **4 种兼容格式**：

### 格式 1：多清晰度视频（含音频和封面）

```json
{
  "code": 200,
  "msg": "success",
  "data": {
    "video_list": [
      {"url": "https://video.com/hd.mp4", "level": "高清"},
      {"url": "https://video.com/sd.mp4", "level": "标清"}
    ],
    "cover": "https://image.com/cover.jpg",
    "music": "https://audio.com/bgm.mp3",
    "images": [
      "https://image.com/extra1.jpg",
      "https://image.com/extra2.jpg"
    ]
  }
}
```

### 格式 2：单个视频资源（含封面）

```json
{
  "code": 200,
  "msg": "success",
  "data": {
    "video_url": "https://video.com/main.mp4",
    "cover": "https://image.com/thumbnail.jpg",
    "music_url": "https://audio.com/soundtrack.mp3"
  }
}
```

### 格式 3：纯图片资源

```json
{
  "code": 200,
  "msg": "success",
  "data": {
    "images": [
      "https://image.com/photo1.jpg",
      "https://image.com/photo2.jpg"
    ],
    "pics": "https://image.com/cover.png",
    "img": [
      "https://image.com/additional.jpg"
    ]
  }
}
```

### 格式 4：混合资源（视频 + 图片）

```json
{
  "code": 200,
  "msg": "success",
  "data": {
    "url": "https://video.com/short.mp4",
    "videos": [
      "https://video.com/extra.mp4"
    ],
    "cover": "https://image.com/poster.jpg",
    "images": [
      "https://image.com/screenshot1.png",
      "https://image.com/screenshot2.png"
    ]
  }
}
```

### 字段解析优先级

DYYY 按以下顺序查找资源（优先级从高到低）：

| 字段名 | 类型 | 说明 |
|--------|------|------|
| `video_list` | 对象数组 | 多清晰度选项，含 `url` 和 `level` 字段；选择后可下载对应清晰度的视频 |
| `videos` | 字符串数组 | 多个视频资源的 URL 集合 |
| `video_url` | 字符串 | 单个视频资源 URL（优先使用字段） |
| `video` | 字符串 | 单个视频资源 URL（备用字段） |
| `url` | 字符串 | 通用资源 URL（视频优先） |
| `cover` | 字符串 | 封面图 URL（主字段） |
| `pics` | 字符串 | 封面图 URL（备用字段） |
| `music` | 字符串 | 背景音乐 URL（主字段） |
| `music_url` | 字符串 | 背景音乐 URL（备用字段） |
| `images` | 字符串数组 | 附加图片资源集合 |
| `img` | 字符串数组 | 附加图片资源集合（备用字段） |

> **提示**：API 必须返回 `"code": 200` 才会被 DYYY 识别为成功。其他状态码将被忽略。

---

## 音频助手与语音收藏夹

DYYY 内置了一个 **语音收藏夹**（英文：Voice Favorites），用于收藏、管理和播放你喜爱的音频片段。

### 核心功能

- **保存音频**：将下载的音频保存到收藏夹（可自定义名称）
- **播放收藏**：在收藏夹中直接播放已保存的音频
- **文件管理**：支持重命名、删除、创建文件夹
- **目录浏览**：按文件夹层级查看收藏的音频
- **存储位置**：所有音频保存到应用的 `Documents/DYYY/` 目录，持久化存储

### 语音收藏夹入口

通过长按面板中的「语音收藏夹」入口进入（需在设置中启用 `DYYYLongPressVoiceFavorites`）。

### 音频限制

- 单个音频文件大小上限：**50 MB**
- 音频时长上限：**29.5 秒**（变声处理限制）

---

## 私信变声器

DYYY 内置了 **私信语音变声器**，可在发送语音消息前自动将原始录音替换为变声后的音频。

### 工作原理

1. Hook `NSFileManager` 的 `moveItemAtPath:toPath:error:` 方法
2. 精准匹配抖音私信的音频缓存路径（`AWEIMRoot/attachment` 目录下 `.m4a` 文件）
3. 在文件写入目标位置前，调用 `DYYYVoiceChanger` 进行音频处理
4. 将变声后的文件替代原始文件发送给抖音服务器

### 支持的变声效果

| 模式 | 编号 | 说明 |
|------|------|------|
| 正常原声 | 0 | 不做任何处理，直接发送原始语音 |
| 夹子 / 萝莉音 | 1 | 提高音调，制造可爱萝莉音效 |
| 沉稳大叔音 | 2 | 降低音调，制造成熟大叔音效 |
| 空灵混响（大厅） | 3 | 添加混响效果，模拟大厅/空旷空间感 |
| 无情机器（电音） | 4 | 添加电音效果，模拟机器人/电子音 |
| 恶魔低语 | 5 | 降低音调 + 混响，制造深沉诡异的低语效果 |

### 配置方式

在 DYYY 设置面板 →「面板设置」→「私信变声器」中选择需要的变声类型。选择后立即生效，下一次发送私信语音时将自动应用。

### 容错机制

- 处理失败时 **不会阻断消息发送**，自动回退为原始音频
- 处理成功时，原始文件被替换为 `_changed.m4a` 后缀的变声文件
- 调试日志保存在临时目录的 `DYYY_Debug.log` 中（自动轮转，最大 5 MB）

---

## 版本兼容性说明

| 项目 | 说明 |
|------|------|
| **已测试的抖音版本** | **35.1.0**（这是唯一经过完整测试的版本） |
| **最低 iOS 版本** | iOS 14.0 |
| **支持的架构** | arm64 / arm64e |
| **越狱类型** | Rootful、Rootless（Dopamine）、RootHide 均支持 |
| **其他抖音版本** | 理论支持相近版本，但 **不做保证**。不同版本的私有 API 类名和方法签名可能发生变化，导致部分 Hook 失效 |

> **建议**：使用 AppStore++ 或 AppStore 降级工具固定抖音版本为 35.1.0，确保所有功能正常运作。未来将根据需求适配更多抖音版本。

---

## 常见问题（FAQ）

### Q1：安装后没有任何效果？

**A**：请按以下步骤排查：

1. 确认设备已越狱，且 MobileSubstrate / libhooker 正常工作
2. 确认安装的版本与你的越狱类型匹配（Rootful / Rootless / RootHide）
3. 在终端执行 `dpkg -l | grep dyyy`，确认包已正确安装
4. 完全关闭抖音后台（`killall Aweme`），重新打开
5. 尝试双指长按屏幕，看是否弹出设置面板

### Q2：部分功能开关无效？

**A**：这些功能可能依赖于特定的 UI 视图类，而你的抖音版本中这些类的名称可能已变更。DYYY 仅在 **35.1.0 版本** 上完整测试。建议降级抖音到此版本。

### Q3：私信变声器没效果？

**A**：确认：

1. 在设置中已选择非「正常原声」的变声类型
2. 发送的是 **语音消息**（按住录音），而不是文字消息
3. 语音时长不超过 29.5 秒
4. 检查临时目录 `DYYY_Debug.log` 查看处理日志

### Q4：远程配置拉取失败？

**A**：

1. 确认设备网络正常，可以访问配置文件 URL
2. 检查配置文件的 JSON 格式是否正确（可以使用在线 JSON 校验工具）
3. v2.2-9 版本起有 Schema 白名单校验，尝试只使用 `mode`、`data`、`version`、`description` 四个顶层键
4. 检查 GitHub RAW 下载链接是否有效

### Q5：卸载 DYYY 后抖音崩溃？

**A**：通常不会。DYYY 是纯运行时注入的 Tweak，卸载后不会修改 App 本体。如果遇到问题：

```bash
# 完全卸载
ssh root@设备IP "dpkg -r com.xiaopan.dyyy"

# 清除偏好设置残留
ssh root@设备IP "rm -f /var/mobile/Library/Preferences/com.xiaopan.dyyy.plist"

# 清理 DYYY 数据目录
ssh root@设备IP "rm -rf /var/mobile/Documents/DYYY"

# 重新安装抖音（如有必要）
```

### Q6：怎么更新 DYYY？

**A**：下载最新的 `.deb` 包，通过 SSH 安装覆盖即可：

```bash
scp com.xiaopan.dyyy_*.deb root@设备IP:/tmp/
ssh root@设备IP "dpkg -i --force-overwrite /tmp/com.xiaopan.dyyy_*.deb"
```

### Q7：直播隐身模式真的完全不显示吗？

**A**：DYYY Hook 了 `HTSLiveUser`、`IESLiveUserModel`、`AWEUserModel` 三个级别的用户模型，强制将 `secret` / `isSecret` 返回 `YES`，`displayEntranceEffect` 返回 `NO`。从技术上讲，你的设备不会向直播间广播进场通知。但请注意，直播间的公屏礼物、点赞等互动行为仍然可见。

### Q8：无痕浏览有被封号的风险吗？

**A**：DYYY 采取保守策略，**只拦截浏览类埋点**（进入主页、浏览记录），而不拦截点赞、评论等正常互动事件的埋点。这样做是为了避免触发字节跳动的风控机制。目前的实践表明这种策略是安全的，但仍请以学习研究为目的使用。

### Q9：能适配最新版抖音吗？

**A**：DYYY 依赖大量私有 API 类名和方法名。抖音每个版本都可能对这些内部接口进行改动，因此一个版本更新可能导致数十个 Hook 失效。适配新版本需要逐一排查、重写 Hook 逻辑，工作量极大。建议通过 AppStore 降级工具保持在 35.1.0 版本使用。

---

## 贡献指南

欢迎对 DYYY 做出贡献！以下是一些贡献方式：

### 代码贡献

1. Fork 本仓库
2. 创建功能分支：`git checkout -b feature/my-feature`
3. 确保你的代码符合现有代码风格（参考 `.clang-format` 配置）
4. 在干净环境中测试编译：`make clean && make package`
5. 在越狱设备上测试功能是否正常
6. 提交 PR，描述你的改动和测试情况

### 文档贡献

- 修正文档中的错误或过时信息
- 补充 FAQ 条目
- 翻译文档到其他语言
- 编写教程和使用案例

### 报告 Bug

在提交 Issue 前，请先搜索是否已存在相同的 Issue。提交时请包含：

- 抖音版本号
- iOS 版本
- 越狱工具和版本
- DYYY 版本
- 复现步骤
- 预期行为和实际行为

### 开发规范

- 所有新的设置项必须同时在 `DYYYSettingViewController.m` 的 `setupSettingItems` 中注册
- Hook 代码统一使用 `DYYYGetBool()` / `DYYYGetFloat()` / `DYYYGetString()` 读取用户偏好
- 涉及 UI 的操作务必在主线程执行
- 新增文件需在 `Makefile` 的 `DYYY_FILES` 中注册

---

## 更新日志

完整的版本变更记录请参阅 [CHANGELOG.md](./CHANGELOG.md)。

### 最新版本：2.2-9 (2026-07-01)

**关键修复：**

- **ABTest 配置重新加载 Bug**：修复远程配置更新后无法重新加载的问题（移除 `dispatch_once` 限制）
- **NSFileManager Hook 范围过大**：从 `containsString:` 改为路径组件精确匹配，避免误拦截非私信附件
- **静态全局变量竞态条件**：为手势相关全局变量（`gStartY` / `gStartVal` / `gMode` / `gFeedCV`）添加 `os_unfair_lock` 保护
- **远程配置 JSON Schema 校验**：新增白名单校验函数，拒绝包含未知键或非法类型的配置，防止恶意 JSON 注入

---

## 许可证

本项目基于 **MIT License** 开源，详见 [LICENSE](./LICENSE) 文件。

```
MIT License

Copyright (c) 2024 huami.

Permission is hereby granted, free of charge, to any person...
```

> **免责声明**：本项目仅供**学习研究** iOS 逆向工程和 Theos/Logos 开发技术。使用者需在下载后的 24 小时内自行删除。请勿将本项目用于任何违反《中华人民共和国网络安全法》及相关法律法规的用途。使用者需自行承担一切责任。

---

> **Developer**: [@huamidev](https://github.com/huami1314)  
> **项目主页**: [https://github.com/huami1314/DYYY](https://github.com/huami1314/DYYY)  
> **Telegram 频道**: [@huamidev](https://t.me/huamidev)
