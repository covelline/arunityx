# Apple Silicon (M1/M2/M3) Mac の Docker は aarch64 で動くが、
# Android NDK のホスト向けツールチェインは linux-x86_64 のみ提供されているため
# --platform linux/amd64 で x86_64 (Rosetta 2 エミュレーション) を強制する。
FROM --platform=linux/amd64 ubuntu:22.04

# ビルドに必要なパッケージをインストール
ENV DEBIAN_FRONTEND=noninteractive
RUN apt-get update && apt-get install -y \
    cmake \
    git \
    curl \
    unzip \
    patch \
    make \
    ninja-build \
    && rm -rf /var/lib/apt/lists/*

# [Covelline] NDK 27 を使用する。
# NDK 27 の libc++_shared.so は 16KB ページサイズ対応済み (Align=0x4000)。
# NDK 26 以前は 4KB アライメント (Align=0x1000) のため使用しない。
ENV NDK_VERSION=r27
ENV ANDROID_HOME=/opt/android

RUN mkdir -p ${ANDROID_HOME}/ndk && \
    curl -fL "https://dl.google.com/android/repository/android-ndk-${NDK_VERSION}-linux.zip" \
        -o /tmp/ndk.zip && \
    unzip -q /tmp/ndk.zip -d /tmp/ndk-unpack && \
    mv /tmp/ndk-unpack/android-ndk-${NDK_VERSION} ${ANDROID_HOME}/ndk/27.0.12077973 && \
    rm -f /tmp/ndk.zip && \
    # artoolkitX の CMake ビルドは ndk-bundle パスを参照するためシンボリックリンクを作成
    ln -sf ${ANDROID_HOME}/ndk/27.0.12077973 ${ANDROID_HOME}/ndk-bundle

WORKDIR /work
