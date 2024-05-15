#!/bin/bash

TARGET=$1
ARCH=$(cut -d'-' -f1 <<< "$TARGET")
OTHER=$(cut -d'-' -f4 <<< "$TARGET")
PACKAGE_ARCH="NOPE"
TARGETS=$(rustc --print target-list)

if grep -xq "$TARGET" <<< "$TARGETS"; then
    echo "Target $TARGET is supported."
else
    echo "Target $TARGET is not supported."
    exit 1
fi

case $ARCH in
    arm)
    case $OTHER in
        gnueabihf | musleabihf)
        PACKAGE_ARCH="armhf"
        LINKER=gcc-arm-linux-gnueabihf
        ;;
        gnueabi | musleabi)
        PACKAGE_ARCH="armel"
        LINKER=gcc-arm-linux-gnueabi
        ;;
        *)
        echo "Unsupported architecture: $ARCH-$OTHER"
        exit 1
        ;;
    esac
    ;;
    aarch64)
    PACKAGE_ARCH="arm64"
    LINKER=gcc-aarch64-linux-gnu
    ;;
    x86_64)
    PACKAGE_ARCH="amd64"
    LINKER=gcc-x86_64-linux-gnu
    ;;
    i686)
    PACKAGE_ARCH="i386"
    LINKER=gcc-i686-linux-gnu
    ;;
    *)
    echo "Unsupported architecture: $ARCH"
    exit 1
    ;;
esac
export DEBIAN_FRONTEND=noninteractive
# pass package arch to github output
echo "::set-output name=package_arch::$PACKAGE_ARCH"
echo "::set-output name=linker::$LINKER"
# if not debug, run `sudo apt-get -y install crossbuild-essential-$PACKAGE_ARCH`
if [[ -n "$DEBUG" ]]; then
    sudo apt-get -y install crossbuild-essential-$PACKAGE_ARCH
fi
