## Welcome to artoolkitX for Unity

### What is artoolkitX for Unity?

artoolkitX for Unity is a software development kit (SDK) consisting of script components, plugins, and utilities that help developers implement the foundation of great augmented and mixed reality applications inside the Unity development environment. The SDK includes some examples of applications that demonstrate the capabilities of artoolkitX for Unity.

artoolkitX for Unity is free to use! The SDK is licensed under the GNU Lesser General Public License version 3.0, with some additional permissions, allowing for linking into both closed- and open-source software. Please read the file license to understand your rights and obligations when using artoolkitX. Example code is generally released under a more permissive disclaimer; please read the file LICENSE.txt for more information.

### System Requirements:

artoolkitX for Unity is designed to build on Windows, Macintosh OS X, iOS and Android platforms.

In addition to any base requirements for Unity, the artoolkitX for Unity plugin(s) have the following requirements:
* artoolkitX for Unity on iOS: an iOS device running iOS 11.0 or later is required.
* artoolkitX for Unity on Android: an Android device running Android 7.0 or later is required.
* artoolkitX for Unity on mac OS: a Mac running mac OS 10.13 or later is required.
* artoolkitX for Unity on Windows: a 64-bit PC running Windows 10 or later is required.

### Support

For experienced developers wanting to quickly make use of the SDK, please read the file [Quick start](Documentation%7e/Quick%20start.md). To read about the changes in this release, please read the file [Release notes](Documentation%7e/Release%20notes.md).

Please check out [documentation][documentation] for more information on how to use artoolkitX for Unity. If you find a bug, please note it on our [issue tracker][https://github.com/artoolkitx/arunityx/issues], and / or, fix it yourself and submit a [pull request][pull]!

[website]: http://www.artoolkitx.org
[documentation]: https://github.com/artoolkitx/arunityx/wiki
[issue tracker]: https://github.com/artoolkit/arunity5/issues
[pull]: https://github.com/artoolkitx/arunityx/pulls

---

## Covelline フォーク について

このリポジトリは [artoolkitx/arunityx](https://github.com/artoolkitx/arunityx) の Covelline 管理フォークです。
`upm2` ブランチが Unity Package Manager (UPM) からインストールするパッケージ本体です。

### 公式からの変更点

#### 1. cparamSearch の無効化

artoolkitX 公式サーバからデバイスのカメラ歪みパラメータをダウンロードする機能 (cparamSearch) を無効化しています。
オフライン環境でタイムアウト待ちが発生して動作が著しく遅くなるためです。

#### 2. NFT マーカーの絶対パス読み込み

`ARXTrackable.cs` の NFT タイプでマーカーデータを絶対パスで読み込むよう変更しています (`Runtime/Scripts/ARXTrackable.cs`)。

#### 3. Android 16KB ページサイズ対応

Android 15 以降の端末・Google Play Store の要件に対応するため、ネイティブライブラリを 16KB アライメントでビルドしています。

---

## ネイティブライブラリのビルド方法

`Runtime/Plugins/Android/libs/` 以下の `.so` ファイルは、Docker を使ってビルドします。

### 前提条件

- Docker が起動していること

### ビルド手順

```bash
cd native-build/
./build.sh
```

初回はDockerイメージのビルドと NDK・OpenCV のダウンロードがあるため時間がかかります（目安: 30分〜1時間）。

### ビルドの概要

| 項目 | 内容 |
|------|------|
| ベースソース | [artoolkitx/artoolkitx](https://github.com/artoolkitx/artoolkitx) タグ `1.1.16` |
| ビルド環境 | Ubuntu 22.04 (Docker) |
| Android NDK | 27.0.12077973 (16KB ページサイズ対応版) |
| 適用パッチ | `native-build/patches/cmake-changes.patch` |

### ビルドで更新されるファイル

```
Runtime/Plugins/Android/libs/
  arm64-v8a/
    libARX.so         ← artoolkitx 1.1.16 をパッチ適用してビルド
    libc++_shared.so  ← NDK 27 から取得 (16KB 対応済み)
  armeabi-v7a/        ← 同様
  x86/                ← 同様
  x86_64/             ← 同様
```

ビルド完了後、差分を確認して `git commit` してください。
