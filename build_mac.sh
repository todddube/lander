#!/bin/bash
# Build script for Lunar Lander on macOS
# Prefers CMake; falls back to direct clang++ compilation.
# Usage: ./build_mac.sh [Debug|Release]
set -e

BUILD_TYPE="Release"

for arg in "$@"; do
    case "$arg" in
        Debug|debug)     BUILD_TYPE="Debug" ;;
        Release|release) BUILD_TYPE="Release" ;;
        *)               echo "Unknown argument: $arg (ignored)" ;;
    esac
done

VERSION=$(cat VERSION 2>/dev/null || echo "1.0.0")
mkdir -p build

echo "========================================"
echo "Building Lander v$VERSION [$BUILD_TYPE]"
echo "========================================"

if command -v cmake &>/dev/null; then
    echo "[CMake] Configuring..."
    cmake -B build -S . -DCMAKE_BUILD_TYPE="$BUILD_TYPE"
    echo "[CMake] Building..."
    cmake --build build --config "$BUILD_TYPE"
else
    echo "[clang++] Direct compilation..."

    CFLAGS="-std=c++17 -Wall -Wextra -Wpedantic -x objective-c++"
    CFLAGS="$CFLAGS -mmacosx-version-min=12.0"
    CFLAGS="$CFLAGS -DLANDER_VERSION_STRING='\"$VERSION\"'"
    CFLAGS="$CFLAGS -DLANDER_AUTHOR='\"Todd Dube\"'"
    CFLAGS="$CFLAGS -DLANDER_COPYRIGHT='\"Copyright (c) 2025 Todd Dube\"'"

    if [ "$BUILD_TYPE" = "Debug" ]; then
        CFLAGS="$CFLAGS -g -O0 -DDEBUG"
    else
        CFLAGS="$CFLAGS -O2 -DNDEBUG"
    fi

    # shellcheck disable=SC2086
    clang++ $CFLAGS \
        -framework Cocoa \
        -framework CoreGraphics \
        -framework CoreText \
        -framework AudioToolbox \
        -o build/lander \
        lander.cpp
fi

echo ""
echo "========================================"
echo "Build successful: build/lander"
echo "========================================"
