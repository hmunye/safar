<div align="center">

<img src="https://github.com/user-attachments/assets/6d153671-a62e-443f-a517-da4e0343cc51#gh-light-mode-only" width="270px" alt="safar logo"/>
<img src="https://github.com/user-attachments/assets/8828f00c-de2f-4fba-b143-0d40c841307a#gh-dark-mode-only"  width="270px" alt="safar logo"/>

[![MIT Licensed](https://img.shields.io/badge/license-MIT-blue.svg)](https://github.com/hmunye/safar/blob/main/LICENSE)
</div>

An iOS application for transcribing Quran recitation clips on-device, with offline
verse identification and playback through a scrollable feed.

## Features

- Transcribe Quran recitations on-device and identify the recited verses
- Import recitation clips from the Photos library or [URL sources](#url-import)
- Preview imported clips with audio playback and identified chapters and verses
  before saving
- Browse saved recitations in a vertical, swipeable feed with background playback
  and audio repeat
- Follow along with recitations through right-to-left verse scrolling and per-verse
  translations

## URL Import

The **optional** URL Import feature requires [`yt-dlp`](https://github.com/yt-dlp/yt-dlp)
and `ffmpeg`.

After completing the [Setup](#setup) and [Build](#build) steps, install the required
dependencies:

```bash
brew install ffmpeg yt-dlp
```

Start the URL Import server:

```bash
python3 server.py
```

Copy the example configuration:

```bash
cp Safar/Config/Config.xcconfig Safar/Config/Release.xcconfig
```

Update `Config/Release.xcconfig` with the server address:

```xcconfig
SERVER_IP = <server-ip>
SERVER_PORT = <server-port>
```

Rebuild and run the app in Xcode (`⌘R`).

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

Prepare the on-device model, [`tarteel-ai/whisper-base-ar-quran`](https://huggingface.co/tarteel-ai/whisper-base-ar-quran),
converted for use with [`ggml-org/whisper.cpp`](https://github.com/ggml-org/whisper.cpp):

```bash
./prepare_model.sh
```

## Build

Build the dependencies required by the Xcode project for iOS device and simulator:

```bash
cd Sources/SafarCore
./build_ios.sh
```

Open `Safar.xcodeproj` in Xcode.

Connect your iOS device and ensure **Developer Mode** is enabled: [Enable Developer Mode on iPhone or iPad](https://developer.apple.com/documentation/xcode/enabling-developer-mode-on-a-device)

After pairing with Xcode, select your connected device as the **Run Destination**.

Configure **Signing**:

- Add your Apple account under **Xcode Settings -> Apple Accounts**
- In the project settings, open **Signing & Capabilities** and select your Personal Team
- Update the **Bundle Identifier** if required

Build and run the app (`⌘R`).

For additional Xcode device setup details, see Apple's documentation:
[Running your app on simulated or physical devices](https://developer.apple.com/documentation/Xcode/running-your-app-on-simulated-or-physical-devices)

## License

This project is licensed under the [MIT License].

[MIT License]: https://github.com/hmunye/safar/blob/main/LICENSE
