# Simple Conference Example using SwiftUI

A SwiftUI example app that demonstrates how to integrate the AuviousSDK to create audio/video conference calls.

## Setup

- Include AuviousSDK CocoaPod from Auvious CocoaPod repo, see `Podfile`
- Disable bitcode target under **Build Settings**
- Add `NSMicrophoneUsageDescription` and `NSCameraUsageDescription` texts in `Info.plist`

## Usage

1. Enter a **ticket** (used as the username for authentication).
2. Enter an **environment** (the Auvious server hostname, defaults to `auvious.video`).
3. Configure the toggles below to control conference features.
4. Tap one of the call buttons to start a conference:
   - **Audio Call** — audio only (`callMode = .audio`)
   - **Camera Call** — camera only, no microphone (`callMode = .video`)
   - **Video Call** — audio and video (`callMode = .audioVideo`)

## SDK Configuration Flags

These flags are set on `AuviousConferenceConfiguration` before launching the conference view controller.

| Toggle | Config Property | Description |
|---|---|---|
| **audio output to speaker** | `enableSpeaker` | Routes audio output to the device speaker instead of the earpiece. |
| **camera** | `cameraAvailable` | Shows or hides the camera toggle button in the conference UI. When disabled, the user cannot enable their camera during the call. |
| **microphone** | `microphoneAvailable` | Shows or hides the microphone toggle button in the conference UI. When disabled, the user cannot unmute during the call. |
| **speaker** | `speakerAvailable` | Shows or hides the speaker toggle button in the conference UI. When disabled, the user cannot switch audio output during the call. |
| **share screen** | `screenSharingAvailable` | Enables the screen sharing capability. When enabled, a screen share button appears in the conference UI allowing the user to broadcast their screen to other participants. |
| **Floating window** | `pipAvailable` | Enables Picture-in-Picture (PiP) mode. When enabled, the conference video can be minimized into a floating overlay window that stays visible while using other apps. |
| **custom background** | `conferenceBackgroundColor` | Sets a custom background color for the conference view. When enabled the background is blue; when disabled it is black. |
| **background audio** | `backgroundAudioEnabled` | Keeps the audio session active when the app moves to the background. When enabled, conference audio continues playing even if the user switches to another app. |
