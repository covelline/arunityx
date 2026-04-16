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

echo "==> ソースを変更中..."
# patch コマンドは blank 行や文字コードの扱いが繊細なため、Python で直接書き換える。
# 変更内容の差分は patches/cmake-changes.patch に記録してある。
python3 << 'EOF'
import sys

# --- CMakeLists.txt の変更 ---
# [Covelline] Android ビルドの USE_CPARAM_SEARCH を 0 に変更し、16KB フラグを追加する。
cmake_path = "/tmp/artoolkitx/Source/CMakeLists.txt"
with open(cmake_path, "r") as f:
    content = f.read()

original = 'elseif(ARX_TARGET_PLATFORM_ANDROID)\n\n    set(USE_CPARAM_SEARCH 1)\n    set(ARX_INSTALL_LIBRARY_DIR "lib/${ANDROID_ABI}")'
replaced = (
    'elseif(ARX_TARGET_PLATFORM_ANDROID)\n\n'
    '    # [Covelline] cparamSearch 無効化 (オフライン時のタイムアウト問題対策)\n'
    '    set(USE_CPARAM_SEARCH 0)\n'
    '    set(ARX_INSTALL_LIBRARY_DIR "lib/${ANDROID_ABI}")\n'
    '    # [Covelline] Android 16KB ページサイズ対応フラグ\n'
    '    set(CMAKE_SHARED_LINKER_FLAGS "${CMAKE_SHARED_LINKER_FLAGS} -Wl,-z,max-page-size=16384")'
)
if original not in content:
    print("ERROR: CMakeLists.txt の書き換え対象が見つかりません。artoolkitx のバージョンが想定外の可能性があります。")
    sys.exit(1)
content = content.replace(original, replaced)
with open(cmake_path, "w") as f:
    f.write(content)
print("CMakeLists.txt 変更完了: USE_CPARAM_SEARCH=0, -Wl,-z,max-page-size=16384")

# --- cparamSearch.h にスタブ定義を追加 ---
# [Covelline] videoAndroid.cpp は #if USE_CPARAM_SEARCH ガードなしで cparamSearch の関数・型を直接呼んでいる。
# USE_CPARAM_SEARCH=0 にすると宣言が消えてコンパイルエラーになるため、
# #else ブランチに何もしないスタブ定義を追加して対処する。
header_path = "/tmp/artoolkitx/Source/ARX/ARVideo/cparamSearch.h"
with open(header_path, "r") as f:
    header = f.read()

stub = (
    "\n#else // !USE_CPARAM_SEARCH - スタブ定義 (cparamSearch 無効時のコンパイルエラー回避)\n"
    "#include <ARX/ARVideo/video.h>\n"
    "typedef enum {"
    " CPARAM_SEARCH_STATE_INITIAL=0,CPARAM_SEARCH_STATE_IN_PROGRESS=1,"
    "CPARAM_SEARCH_STATE_RESULT_NULL=2,CPARAM_SEARCH_STATE_OK=3,"
    "CPARAM_SEARCH_STATE_FAILED_ERROR=-1,CPARAM_SEARCH_STATE_FAILED_NO_NETWORK=-2,"
    "CPARAM_SEARCH_STATE_FAILED_NETWORK_FAILED=-3,CPARAM_SEARCH_STATE_FAILED_SERVICE_UNREACHABLE=-4,"
    "CPARAM_SEARCH_STATE_FAILED_SERVICE_UNAVAILABLE=-5,CPARAM_SEARCH_STATE_FAILED_SERVICE_FAILED=-6,"
    "CPARAM_SEARCH_STATE_FAILED_SERVICE_NOT_PERMITTED=-7,CPARAM_SEARCH_STATE_FAILED_SERVICE_INVALID_REQUEST=-8"
    " } CPARAM_SEARCH_STATE;\n"
    "typedef void (*CPARAM_SEARCH_CALLBACK)(CPARAM_SEARCH_STATE state, float progress, const ARParam *cparam, void *userdata);\n"
    "#ifdef __cplusplus\nextern \"C\" {\n#endif\n"
    "static inline int cparamSearchInit(const char *a,const char *b,int c,const char *d,const char *e)"
    "{(void)a;(void)b;(void)c;(void)d;(void)e;return 0;}\n"
    "static inline int cparamSearchFinal(void){return 0;}\n"
    "static inline int cparamSearchSetInternetState(int s){(void)s;return 0;}\n"
    "static inline CPARAM_SEARCH_STATE cparamSearch(const char *a,int b,int c,int d,float e,CPARAM_SEARCH_CALLBACK f,void *g)"
    "{(void)a;(void)b;(void)c;(void)d;(void)e;(void)f;(void)g;return CPARAM_SEARCH_STATE_RESULT_NULL;}\n"
    "#ifdef __cplusplus\n}\n#endif\n"
)

target = "#endif // USE_CPARAM_SEARCH"
if target not in header:
    print("ERROR: cparamSearch.h の構造が想定外です")
    sys.exit(1)
header = header.replace(target, stub + target)
with open(header_path, "w") as f:
    f.write(header)
print("cparamSearch.h スタブ追加完了")
EOF

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
