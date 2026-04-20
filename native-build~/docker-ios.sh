#!/bin/bash
# docker-ios.sh
# Docker コンテナ内で実行されるスクリプト。
# ソース準備（docker-common.sh）後、iOS ビルドに必要な依存関係を用意する。
# ビルド自体は Xcode が必要なためホスト側（build-ios.sh）で行う。
# /output はホスト側の .ios-src/ にマウントされ、キャッシュとして永続化される。

set -e

source /docker-common.sh

OUTPUT_DIR="/output"

prepare_source "${OUTPUT_DIR}"

if [ ! -d "${OUTPUT_DIR}/Source/depends/ios/Frameworks/opencv2.framework" ]; then
    echo "==> OpenCV for iOS をダウンロード中..."
    mkdir -p "${OUTPUT_DIR}/Source/depends/ios/Frameworks"
    curl -fL "https://github.com/artoolkitx/opencv/releases/download/4.6.0/opencv-4.6.0-ios-framework.zip" \
        -o /tmp/opencv2.zip
    unzip -q /tmp/opencv2.zip -d "${OUTPUT_DIR}/Source/depends/ios/Frameworks"
    rm /tmp/opencv2.zip
else
    echo "==> OpenCV キャッシュあり、ダウンロードをスキップ"
fi

echo "==> iOS ソース準備完了"
