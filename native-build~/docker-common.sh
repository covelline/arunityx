#!/bin/bash
# docker-common.sh
# Docker コンテナ内で source して使う共通処理。
# android・iOS 両方の Docker スクリプトから利用する。

ARTOOLKITX_VERSION="1.1.17"

# artoolkitX ソースのクローンとパッチ適用。
# TARGET_DIR にキャッシュ (.git) があればスキップする。
prepare_source() {
    local TARGET_DIR="$1"
    if [ ! -d "${TARGET_DIR}/.git" ]; then
        echo "==> artoolkitX ${ARTOOLKITX_VERSION} をクローン中..."
        git clone --depth 1 --branch "${ARTOOLKITX_VERSION}" \
            https://github.com/artoolkitx/artoolkitx.git "${TARGET_DIR}"

        echo "==> パッチを適用中..."
        patch -p1 -d "${TARGET_DIR}" < /patches/disable-cparam-search.patch
        patch -p1 -d "${TARGET_DIR}" < /patches/android-16kb-page-size.patch
    else
        echo "==> ソースキャッシュあり、クローン・パッチをスキップ"
    fi
}
