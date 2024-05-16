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
        LINKER=arm-linux-gnueabihf-gcc
        ;;
        gnueabi | musleabi)
        PACKAGE_ARCH="armel"
        LINKER=arm-linux-gnueabi-gcc
        ;;
        *)
        echo "Unsupported architecture: $ARCH-$OTHER"
        exit 1
        ;;
    esac
    ;;
    aarch64)
    PACKAGE_ARCH="arm64"
    LINKER=aarch64-linux-gnu-gcc
    ;;
    x86_64)
    PACKAGE_ARCH="amd64"
    LINKER=x86-64-linux-gnu-gcc
    ;;
    i686)
    PACKAGE_ARCH="i386"
    LINKER=i686-linux-gnu-gcc
    ;;
    *)
    echo "Unsupported architecture: $ARCH"
    exit 1
    ;;
esac
export DEBIAN_FRONTEND=noninteractive
# pass package arch to github output
echo "package_arch=$PACKAGE_ARCH" >> $GITHUB_OUTPUT
echo "linker=$LINKER" >> $GITHUB_OUTPUT
# if not debug, run `sudo apt-get -y install crossbuild-essential-$PACKAGE_ARCH`
if [[ -z "$DEBUG" ]]; then
    sudo apt-get -y install crossbuild-essential-$PACKAGE_ARCH
fi
