#!/bin/bash
# build-ios.sh
# ホスト側で実行するスクリプト。
# Docker でソースを準備し、ホスト側 Xcode で iOS ライブラリをビルドして
# Runtime/Plugins/iOS/libARX.a を更新する。
#
# 使い方:
#   cd native-build~/
#   ./build-ios.sh
#
# 前提条件:
#   - Docker が起動していること
#   - Xcode がインストールされていること

set -e

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
REPO_ROOT="${SCRIPT_DIR}/.."
IOS_PLUGIN_PATH="${REPO_ROOT}/Runtime/Plugins/iOS/libARX.a"
IOS_SRC_DIR="${SCRIPT_DIR}/.ios-src"

if ! xcode-select -p > /dev/null 2>&1; then
    echo "エラー: Xcode が見つかりません。Xcode をインストールしてください。"
    exit 1
fi

echo "==> Docker イメージをビルド中 (arunityx-builder)..."
docker build --platform linux/amd64 -t arunityx-builder "${SCRIPT_DIR}"

mkdir -p "${IOS_SRC_DIR}"

echo "==> Docker でソースを準備中..."
docker run --rm --platform linux/amd64 \
    -v "${SCRIPT_DIR}/patches:/patches:ro" \
    -v "${SCRIPT_DIR}/docker-common.sh:/docker-common.sh:ro" \
    -v "${SCRIPT_DIR}/docker-ios.sh:/docker-ios.sh:ro" \
    -v "${IOS_SRC_DIR}:/output" \
    arunityx-builder \
    bash /docker-ios.sh

echo "==> Xcode で iOS ライブラリをビルド中..."
cd "${IOS_SRC_DIR}/Source"
./build.sh ios

echo "==> libARX.a をコピー中..."
cp "${IOS_SRC_DIR}/SDK/lib/libARX.a" "${IOS_PLUGIN_PATH}"

echo ""
echo "==> 完了。更新されたファイル:"
echo "  Runtime/Plugins/iOS/libARX.a"
echo ""
echo "内容確認後、git commit してください。"
