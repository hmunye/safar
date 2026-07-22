#!/usr/bin/env bash

set -euo pipefail
# set -x

if ! command -v cmake >/dev/null 2>&1; then
    printf "\033[0;31merror: cmake is required\033[0m\n" 1>&2
    printf "Install it with a package manager (e.g., Homebrew):\n" 1>&2
    printf "\n" 1>&2
    printf "  brew install cmake\n" 1>&2
    exit 1
fi

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

MACOS_BUILD="$SCRIPT_DIR/build"
DEVICE_BUILD="$SCRIPT_DIR/build-ios-device"
SIMULATOR_BUILD="$SCRIPT_DIR/build-ios-simulator"

XCFRAMEWORK_OUTPUT="../../XCFramework/SafarCore.xcframework"

build_corpus() {
    printf "\033[0;34m==> building corpus files...\033[0m\n" 1>&2

    cmake \
        -S "$SCRIPT_DIR" \
        -B "$MACOS_BUILD"

    cmake \
        --build "$MACOS_BUILD" \
        --target generate_corpus \
        --config Debug

    printf "\033[0;34m==> copying generated corpus files...\033[0m\n" 1>&2

    mkdir -p "$DEVICE_BUILD"
    mkdir -p "$SIMULATOR_BUILD"

    cp -R "$MACOS_BUILD/generated" "$DEVICE_BUILD"
    cp -R "$MACOS_BUILD/generated" "$SIMULATOR_BUILD"

}

build_ios() {
    printf "\033[0;34m==> building for iOS device...\033[0m\n" 1>&2

    cmake \
        -S "$SCRIPT_DIR" \
        -B "$DEVICE_BUILD" \
        -G Xcode \
        -DBUILD_SHARED_LIBS=OFF \
        -DCMAKE_OSX_ARCHITECTURES=arm64 \
        -DCMAKE_OSX_SYSROOT=iphoneos \
        -DCMAKE_SYSTEM_NAME=iOS \
        -DGGML_METAL=OFF \
        -DGGML_METAL_EMBED_LIBRARY=OFF
        # -DWHISPER_COREML=ON

    cmake \
        --build "$DEVICE_BUILD" \
        --config Release
}

build_simulator() {
    printf "\033[0;34m==> building for iOS simulator...\033[0m\n" 1>&2

    cmake \
        -S "$SCRIPT_DIR" \
        -B "$SIMULATOR_BUILD" \
        -G Xcode \
        -DBUILD_SHARED_LIBS=OFF \
        -DCMAKE_OSX_ARCHITECTURES=arm64 \
        -DCMAKE_OSX_SYSROOT=iphonesimulator \
        -DCMAKE_SYSTEM_NAME=iOS \
        -DGGML_METAL=OFF \
        -DGGML_METAL_EMBED_LIBRARY=OFF
        # -DWHISPER_COREML=ON

    cmake \
        --build "$SIMULATOR_BUILD" \
        --config Release
}

create_xcframework() {
    printf "\033[0;34m==> creating XCFramework...\033[0m\n" 1>&2

    rm -rf "$XCFRAMEWORK_OUTPUT"

    libtool -static \
        -o "$DEVICE_BUILD/bin/Release/libsafar_whisper.a" \
        "$DEVICE_BUILD/bin/Release/libsafar.a" \
        "$DEVICE_BUILD/bin/Release/libwhisper.a" \
        "$DEVICE_BUILD/bin/Release/libggml.a" \
        "$DEVICE_BUILD/bin/Release/libggml-base.a" \
        "$DEVICE_BUILD/bin/Release/libggml-blas.a" \
        "$DEVICE_BUILD/bin/Release/libggml-cpu.a"

    libtool -static \
        -o "$SIMULATOR_BUILD/bin/Release/libsafar_whisper.a" \
        "$SIMULATOR_BUILD/bin/Release/libsafar.a" \
        "$SIMULATOR_BUILD/bin/Release/libwhisper.a" \
        "$SIMULATOR_BUILD/bin/Release/libggml.a" \
        "$SIMULATOR_BUILD/bin/Release/libggml-base.a" \
        "$SIMULATOR_BUILD/bin/Release/libggml-blas.a" \
        "$SIMULATOR_BUILD/bin/Release/libggml-cpu.a"

    xcodebuild -create-xcframework \
        -library "$DEVICE_BUILD/bin/Release/libsafar_whisper.a" \
        -headers "$SCRIPT_DIR/include" \
        -library "$SIMULATOR_BUILD/bin/Release/libsafar_whisper.a" \
        -headers "$SCRIPT_DIR/include" \
        -output "$XCFRAMEWORK_OUTPUT"
}

build_corpus
build_ios
build_simulator
create_xcframework
