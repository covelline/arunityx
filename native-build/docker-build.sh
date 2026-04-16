#!/bin/bash
# docker-build.sh
# Docker コンテナ内で実行されるビルドスクリプト。
# artoolkitx のソースをクローンし、パッチを適用してAndroid向けにビルドする。

set -e

# [Covelline] artoolkitx 1.1.16 を使用する。
# arunityx release/1.2.8 の dev/artoolkitx-version.txt で指定されていたバージョン。
ARTOOLKITX_VERSION="1.1.16"

ARTOOLKITX_SRC="/tmp/artoolkitx"
OUTPUT_DIR="/output"

echo "==> artoolkitx ${ARTOOLKITX_VERSION} をクローン中..."
git clone --depth 1 --branch "${ARTOOLKITX_VERSION}" \
    https://github.com/artoolkitx/artoolkitx.git "${ARTOOLKITX_SRC}"

echo "==> パッチを適用中..."
# cmake-changes.patch の内容:
#   1. cparamSearch 無効化 (USE_CPARAM_SEARCH 0)
#   2. 16KB ページサイズ対応フラグ追加 (-Wl,-z,max-page-size=16384)
patch -p1 -d "${ARTOOLKITX_SRC}" < /patches/cmake-changes.patch

cd "${ARTOOLKITX_SRC}/Source"

echo "==> OpenCV for Android をダウンロード中..."
if [ ! -d "depends/android/include/opencv2" ]; then
    mkdir -p depends/android
    curl -fL "https://github.com/artoolkitx/opencv/releases/download/4.6.0/opencv-4.6.0-dev-artoolkitx-android.tgz" \
        -o opencv2.tgz
    tar xzf opencv2.tgz --strip-components=1 -C depends/android
    rm opencv2.tgz
fi

echo "==> Android 向けビルド開始..."
mkdir -p build-android
cd build-android

ABIS="armeabi-v7a arm64-v8a x86 x86_64"
for abi in $ABIS; do
    echo "  --> ABI: ${abi}"
    mkdir -p "${abi}"
    (cd "${abi}"
    cmake ../.. \
        -DCMAKE_TOOLCHAIN_FILE="${ANDROID_HOME}/ndk-bundle/build/cmake/android.toolchain.cmake" \
        -DANDROID_PLATFORM=android-24 \
        -DANDROID_ABI="${abi}" \
        -DANDROID_ARM_MODE=arm \
        -DANDROID_ARM_NEON=TRUE \
        -DANDROID_STL=c++_shared \
        -DCMAKE_BUILD_TYPE=Release
    cmake --build . --target install/strip
    )
done

echo "==> 成果物をコピー中..."
# ABI ごとに libARX.so と libc++_shared.so をコピーする。
# libc++_shared.so は NDK 27 から生成されるため 16KB アライメント対応済み。
declare -A ABI_TO_TRIPLE=(
    ["arm64-v8a"]="aarch64-linux-android"
    ["armeabi-v7a"]="arm-linux-androideabi"
    ["x86"]="i686-linux-android"
    ["x86_64"]="x86_64-linux-android"
)

NDK_PREBUILT="${ANDROID_HOME}/ndk/27.0.12077973/toolchains/llvm/prebuilt/linux-x86_64"

for abi in $ABIS; do
    mkdir -p "${OUTPUT_DIR}/${abi}"

    # libARX.so: パッチ適用済みソースからビルドしたもの
    cp "${ARTOOLKITX_SRC}/SDK/lib/${abi}/libARX.so" "${OUTPUT_DIR}/${abi}/"

    # [Covelline] libc++_shared.so: NDK 27 から直接コピーして 16KB 対応を確実にする。
    # artoolkitx のビルドが配置する libc++_shared.so と同じファイルだが、
    # NDK バージョンを明示することで意図を明確にしている。
    triple="${ABI_TO_TRIPLE[$abi]}"
    cp "${NDK_PREBUILT}/sysroot/usr/lib/${triple}/libc++_shared.so" "${OUTPUT_DIR}/${abi}/"

    echo "  ${abi}: OK"
done

echo "==> ビルド完了"
