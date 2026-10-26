# QPlayer (iOS / Flutter)

A modern local-music player inspired by [TIMER-err/qplayer](https://github.com/TIMER-err/qplayer),
rebuilt as a Flutter app with an Apple-Music-style **fluid lyrics** page, a local music
library, play queue, play modes (off / list-loop / single-loop), shuffle, and light/dark themes.

> **Note on iOS:** This is an iOS-configured Flutter project. A real `.ipa` can only be
> produced on **macOS + Xcode** (or a cloud Mac build like Codemagic). This project was
> authored and verified on Windows (code compiles cleanly via `flutter analyze`); the final
> `flutter build ios` step must be run on a Mac.

## Feature set (faithful to QPlayer)
- Local music library (via `on_audio_query`)
- Play queue + three play modes + shuffle
- Apple-Music-style **fluid lyrics**: background color is derived from the album art
  (`palette_generator`); the active lyric line is highlighted and auto-scrolled
- Sidecar `.lrc` support — put a `xxx.lrc` next to `xxx.mp3` and it is matched automatically
- Light / dark themes, iOS-style segmented controls and navigation
- Mini player + full-screen Now Playing with seek bar

## Project layout
```
E:\iOS\
  flutter\            Flutter 3.47.8 SDK (bin\flutter.bat)
  pub_cache\         Dart package cache (all deps downloaded here)
  qplayer\           This Flutter project
    lib\
      main.dart
      models/track.dart
      services/library_service.dart   (on_audio_query wrapper)
      services/player_handler.dart    (audio_service + just_audio)
      providers/player_provider.dart  (state, lyrics, fluid color)
      utils/lrc_parser.dart
      theme/app_theme.dart
      widgets/album_art.dart, track_tile.dart, mini_player.dart
      screens/library_screen.dart, now_playing_screen.dart,
              lyrics_screen.dart, settings_screen.dart
    ios\Runner\Info.plist             (music permission + background audio already added)
```

## Build on a Mac (有 Mac 时的正经方式)
1. Copy the `E:\iOS` folder (or just `qplayer/`) onto a Mac with Xcode installed.
2. Install Flutter 3.47.x and open a terminal in `qplayer/`.
3. `flutter pub get`
4. Open `ios/Runner.xcworkspace` in Xcode, select your Team, and under
   **Signing & Capabilities** enable the **Media Library** capability
   (required so `on_audio_query` can read the on-device music library on iOS).
5. `flutter build ios`  (or run via Xcode / `flutter run`).
6. For a distributable archive: **Product → Archive** in Xcode.

---

## 没有 Mac：云端编译 + 自己重签名（本工程采用的方案）
因为 iOS 编译必须在 macOS 上跑，本机（Windows）无法出 IPA。本工程已配好
**「不签名编译」** 的云端构建，打出的 `qplayer-unsigned.ipa` 是**未签名**包，
你再用自己的证书在 Windows 上重签名即可安装。

### 第 1 步：把工程推到 GitHub
```bash
cd E:\iOS\qplayer
git init
git add .
git commit -m "QPlayer iOS (unsigned build ready)"
git branch -M main
git remote add origin https://github.com/<你的用户名>/qplayer.git
git push -u origin main
```

### 第 2 步：触发云端构建（任选一个平台）
- **GitHub Actions（免费，公开仓库不限额）**：仓库里已包含
  `.github/workflows/build-unsigned-ipa.yml`。在 GitHub 仓库的
  **Actions → Build Unsigned iOS IPA → Run workflow** 手动触发；
  或 push 到 main 自动触发。跑完后在 **Artifacts** 下载 `qplayer-unsigned.ipa`。
- **Codemagic（免费额度，不用自己托管仓库）**：仓库根有 `codemagic.yaml`，
  在 codemagic.com 导入仓库即可运行，下载 Artifacts 里的 `qplayer-unsigned.ipa`。

> 构建命令核心是 `flutter build ios --release --no-codesign`，
> 之后把 `Runner.app` 压进 `Payload/` 打成标准 IPA（不签名）。

### 第 3 步：在 Windows 上用你的证书重签名
用 **爱思助手**（工具箱 → IPA 重签名）或 **3uTools** 打开下载的
`qplayer-unsigned.ipa`，导入你的：
- **p12 证书**（含私钥，导出时设的密码）
- **mobileprovision 描述文件**（对应你证书的设备/App ID）

点「开始签名」，得到签名后的 IPA，再用同一工具「安装到设备」即可。
（也可走 AltStore / Sideloadly 等侧载工具，同样支持导入 p12+描述文件。）

### 注意事项
- 若用的是**个人/开发证书（免费 Apple ID）**：安装后约 7 天需重签一次，
  且同时最多 3 个 App；重签 = 重新下载 Artifacts 再走第 3 步。
- 若用的是**企业/分发证书**：按证书有效期（通常 1 年）安装，无需频繁重签。
- iOS 上读本地音乐库需要在 Xcode 的 **Signing & Capabilities 启用 Media Library**
  （已写进 Info.plist 权限文案；能力开关在签名/打包时由你的证书/描述文件决定）。
- 云端构建里 `ios/Flutter/Generated.xcconfig` 等含本机路径的文件已被 .gitignore
  忽略，会在 CI 上由 `flutter pub get` 重新生成为正确路径，不影响构建。

## Android (also supported)
The same code builds on Android. Permissions for `READ_MEDIA_AUDIO` /
`READ_EXTERNAL_STORAGE` are added by `on_audio_query`; `audio_service` handles the
lock-screen / control-center integration. `flutter build apk --release` works once a
full Android SDK + NDK toolchain is available.

## Verified
- `flutter --version` → Flutter 3.47.8 stable, Dart 3.13.7
- `flutter pub get` → 56 dependencies resolved
- `flutter analyze` → **No issues found!**
- `ios/Runner/Info.plist` → valid XML with music + background-audio keys
