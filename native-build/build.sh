#!/bin/bash
# build.sh
# ホスト側で実行するスクリプト。
# Docker イメージをビルドし、コンテナ内でネイティブライブラリをビルドして
# Runtime/Plugins/Android/libs/ 以下の .so ファイルを更新する。
#
# 使い方:
#   cd build/
#   ./build.sh
#
# 前提条件:
#   - Docker が起動していること

set -e

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
REPO_ROOT="${SCRIPT_DIR}/.."
PLUGINS_DIR="${REPO_ROOT}/Runtime/Plugins/Android/libs"

echo "==> Docker イメージをビルド中 (arunityx-builder)..."
docker build -t arunityx-builder "${SCRIPT_DIR}"

echo "==> コンテナ内でビルドを実行中..."
docker run --rm \
    -v "${SCRIPT_DIR}/patches:/patches:ro" \
    -v "${SCRIPT_DIR}/docker-build.sh:/docker-build.sh:ro" \
    -v "${PLUGINS_DIR}:/output" \
    arunityx-builder \
    bash /docker-build.sh

echo ""
echo "==> 完了。更新されたファイル:"
for abi in arm64-v8a armeabi-v7a x86 x86_64; do
    for lib in libARX.so libc++_shared.so; do
        echo "  Runtime/Plugins/Android/libs/${abi}/${lib}"
    done
done
echo ""
echo "内容確認後、git commit してください。"
