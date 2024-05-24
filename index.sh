#!/usr/bin/env bash

set -euo pipefail

TARGET=$1
ARCH=$(cut -d'-' -f1 <<< "$TARGET")
OTHER=$(cut -d'-' -f4 <<< "$TARGET")
PACKAGE_ARCH="NOPE"
TARGETS=$(rustc --print target-list)

declare -A package_arch
package_arch[arm]=arm
package_arch[aarch64]=arm64
package_arch[x86_64]=amd64
package_arch[i686]=i386
PACKAGE_ARCH=${package_arch[$ARCH]}

if grep -xq "$TARGET" <<< "$TARGETS"; then
    echo "Target $TARGET is supported."
else
    echo "Target $TARGET is not supported."
    exit 1
fi

if [[ -z "$PACKAGE_ARCH" ]]; then
    echo "Unsupported architecture: $ARCH"
    exit 1
fi

# handle arm subarchitectures
if [[ "$ARCH" == "arm" ]]; then
    case $OTHER in
        gnueabihf | musleabihf)
        PACKAGE_ARCH="armhf"
        ;;
        gnueabi | musleabi)
        PACKAGE_ARCH="armel"
        ;;
        *)
        echo "Unsupported architecture: $ARCH-$OTHER"
        exit 1
        ;;
    esac
fi
export DEBIAN_FRONTEND=noninteractive
# pass package arch to github output
echo "package_arch=$PACKAGE_ARCH" >> $GITHUB_OUTPUT
if [[ -n "$CI" ]]; then
    sudo apt-get -y install crossbuild-essential-$PACKAGE_ARCH
    mkdir -p ~/.cargo
    cat cargo_config.toml >> ~/.cargo/config.toml
fi