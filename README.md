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

#### 1. Docker

ビルドは Docker コンテナ内で行います。[Docker Desktop](https://www.docker.com/products/docker-desktop/) をインストールして起動してください。

インストール後、以下で確認できます:

```bash
docker info
```

**推奨設定 (メモリ)**: Docker Desktop の設定でメモリを 4GB 以上に割り当ててください（C++ の 4 ABI 同時ビルドのため）。

**Apple Silicon (M1/M2/M3) Mac の場合 — Rosetta 2 の設定**

このビルドは `--platform linux/amd64` で x86_64 コンテナとして実行されます。
Rosetta 2 を有効にしておくとネイティブ比 約 20% 遅い程度で動作します。

以下の手順で Rosetta 2 を有効にしてください:

1. Docker Desktop を開く
2. **Settings → General**
3. **「Use Virtualization Framework」** にチェック（これが前提条件）
4. **「Use Rosetta for x86_64/amd64 emulation on Apple Silicon」** にチェック
5. **Apply & Restart**

> **補足**: Docker Desktop 4.44.0 以降は「Use Virtualization Framework」がデフォルトで有効になっています。最新版であれば手順 3 はスキップできます。

Rosetta 2 自体がインストールされているかは以下で確認できます:

```bash
/usr/bin/pgrep -q oahd && echo "インストール済み" || echo "未インストール"
```

未インストールの場合は以下でインストールできます:

```bash
softwareupdate --install-rosetta
```

#### 2. Git LFS

このリポジトリでは `.so` ファイルを [Git LFS](https://git-lfs.com/) で管理しています。
Git LFS なしでコミットすると `.so` ファイルが正しく保存されないため、必ずセットアップしてください。

```bash
# Git LFS のインストール (macOS)
brew install git-lfs

# リポジトリで Git LFS を有効化 (初回のみ)
git lfs install
```

インストール済みかどうかは以下で確認できます:

```bash
git lfs version
```

#### 3. ディスク空き容量

初回ビルド時に以下をダウンロードするため、**3GB 以上**の空き容量が必要です。

| ダウンロード内容 | サイズ目安 |
|----------------|-----------|
| Android NDK 27 | 約 1.5GB |
| OpenCV for Android | 約 250MB |
| その他ビルド成果物 | 約 200MB |

2回目以降は Docker イメージがキャッシュされるため追加ダウンロードは不要です。

### ビルド手順

```bash
cd native-build~/
./build.sh
```

初回は NDK・OpenCV のダウンロードとビルドがあるため時間がかかります（目安: 30分〜1時間）。

### ビルドの概要

| 項目 | 内容 |
|------|------|
| ベースソース | [artoolkitx/artoolkitx](https://github.com/artoolkitx/artoolkitx) タグ `1.1.16` |
| ビルド環境 | Ubuntu 22.04 (Docker) |
| Android NDK | 27.0.12077973 (16KB ページサイズ対応版) |
| 適用パッチ | `native-build~/patches/cmake-changes.patch` |

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

### Docker イメージの削除

ビルドが完了し、しばらく使わない場合は Docker イメージを削除してディスク容量を解放できます。

```bash
docker rmi arunityx-builder
```

次回ビルド時は `./build.sh` を実行すると自動的にイメージが再作成されます（NDK・OpenCV は再ダウンロードが必要です）。
