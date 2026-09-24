<div align="center">

<img src="https://github.com/user-attachments/assets/6d153671-a62e-443f-a517-da4e0343cc51#gh-light-mode-only" width="270px" alt="safar logo"/>
<img src="https://github.com/user-attachments/assets/8828f00c-de2f-4fba-b143-0d40c841307a#gh-dark-mode-only"  width="270px" alt="safar logo"/>

[![MIT Licensed](https://img.shields.io/badge/license-MIT-blue.svg)](https://github.com/hmunye/safar/blob/main/LICENSE)
</div>

An iOS application for identifying and understanding Quran recitations you
encounter. Import a recitation to identify the verses being recited, save it to
your personal library, then explore its context.

## Features

- On-device, offline Quran recitation transcription and verse identification
- Support for live recording and Photos Library import
- Identified verse(s) preview with audio playback for confirmation before saving
- Vertical, swipeable feed for browsing your personal library
- Background audio playback with automatic repeat
- Synchronized right-to-left Arabic text with per-verse English translations

## Requirements

- [Homebrew](https://brew.sh/)
- Xcode

## Setup

Install the required dependencies:

```bash
brew install git git-lfs python cmake
git lfs install
```

Configure Xcode command-line tools:

```bash
xcode-select --install
sudo xcode-select -s /Applications/Xcode.app/Contents/Developer
```

Clone the repository:

```bash
git clone https://github.com/hmunye/safar.git
cd safar
```

Prepare the on-device model, [tarteel-ai/whisper-base-ar-quran](https://huggingface.co/tarteel-ai/whisper-base-ar-quran),
converted for use with [ggml-org/whisper.cpp](https://github.com/ggml-org/whisper.cpp):

```bash
./prepare_model.sh
```

## Build

Build the native dependencies required by the Xcode project for iOS device and
simulator:

```bash
cd Sources/SafarCore
./build_ios.sh
```

Open `Safar.xcodeproj` in Xcode.

Connect your iOS device and ensure [Developer Mode](https://developer.apple.com/documentation/xcode/enabling-developer-mode-on-a-device) is enabled.

Once your device is paired with Xcode, select it as the **Run Destination**.

To configure **Signing**:

- Add your Apple account under **Xcode →  Settings →  Apple Accounts**
- In the project settings, open **Signing & Capabilities** and select your Personal Team
- Update the **Bundle Identifier** if required

Build and run the app (`⌘+R`).

For additional Xcode device setup details, see Apple's documentation:
[Running your app on simulated or physical devices](https://developer.apple.com/documentation/Xcode/running-your-app-on-simulated-or-physical-devices)

## License

This project is licensed under the [MIT License].

[MIT License]: https://github.com/hmunye/safar/blob/main/LICENSE
