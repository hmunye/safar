# safar

An iOS application for transcribing Quran recitation clips on-device, with offline
processing to identify verses, played back in a scrollable feed.

## Setup

This project uses [`tarteel-ai/whisper-base-ar-quran`](https://huggingface.co/tarteel-ai/whisper-base-ar-quran),
converted for use with [`ggml-org/whisper.cpp`](https://github.com/ggml-org/whisper.cpp).

### Requirements

- git/git-lfs
- python3

To prepare the model, run:

```bash
./prepare_model.sh
```

## Build

This builds `SafarCore` for iOS device and simulator, and packages it into an
XCFramework for the Xcode project to link against.

### Requirements

- CMake
- Xcode (with command-line tools)

```bash
cd Sources/SafarCore/
./build_ios.sh
```

Then open `Safar.xcodeproj` in Xcode and build the project.

## License

This project is licensed under the [MIT License].

[MIT License]: https://github.com/hmunye/safar/blob/main/LICENSE

## References

- [Tanzil](https://tanzil.net/docs/)
