#!/usr/bin/env bash

set -euo pipefail

ROOT="$(cd "$(dirname "$0")" && pwd)"

DEVICE_BUILD="$ROOT/build-ios-device"
SIMULATOR_BUILD="$ROOT/build-ios-simulator"
XCFRAMEWORK_OUTPUT="$ROOT/SafarCore.xcframework"

build_ios() {
    echo "building for iOS device..."

    cmake \
        -S "$ROOT" \
        -B "$DEVICE_BUILD" \
        -G Xcode \
        -DCMAKE_SYSTEM_NAME=iOS \
        -DCMAKE_OSX_SYSROOT=iphoneos \
        -DCMAKE_OSX_ARCHITECTURES=arm64

    cmake \
        --build "$DEVICE_BUILD" \
        --config Release
}

build_simulator() {
    echo "building for iOS simulator..."

    cmake \
        -S "$ROOT" \
        -B "$SIMULATOR_BUILD" \
        -G Xcode \
        -DCMAKE_SYSTEM_NAME=iOS \
        -DCMAKE_OSX_SYSROOT=iphonesimulator \
        -DCMAKE_OSX_ARCHITECTURES=arm64

    cmake \
        --build "$SIMULATOR_BUILD" \
        --config Release
}

create_xcframework() {
    echo "creating XCFramework..."

    rm -rf "$XCFRAMEWORK_OUTPUT"

    xcodebuild -create-xcframework \
        -library "$DEVICE_BUILD/Release-iphoneos/libsafar.a" \
        -headers "$ROOT/include" \
        -library "$SIMULATOR_BUILD/Release-iphonesimulator/libsafar.a" \
        -headers "$ROOT/include" \
        -output "$XCFRAMEWORK_OUTPUT"
}

build_ios
build_simulator
create_xcframework

echo "done: $XCFRAMEWORK_OUTPUT"
