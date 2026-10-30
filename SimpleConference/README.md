# Simple Conference Example

An example app, built from the SDK's `ExampleSimpleConference`, that demonstrates how to integrate the AuviousSDK to create audio/video conference calls.

## Setup

- Include AuviousSDK CocoaPod from Auvious CocoaPod repo, see `Podfile` (iOS 15+, SDK 1.5.0)
- Run `pod install` and open `SimpleConference.xcworkspace`
- Disable bitcode target under **Build Settings**
- Add `NSMicrophoneUsageDescription` and `NSCameraUsageDescription` texts in `Info.plist`

## Structure

The app entry point is SwiftUI (`SimpleConferenceApp`), which hosts the UIKit demo (`ViewController`) in a navigation controller (`MainView`). The SDK pause/resume calls are made from the scene phase in `SimpleConferenceApp`.

## Usage

The screen switches between **Video call** and **Co-browse** at the top.

1. Enter a **ticket** (required) and optionally a **name**; pick the **environment** (PROD, DEV, STG).
2. **Video call**: optionally enter a **conference** name, pick the call mode (audio, video, audio & video) and set the toggles below, then tap **Call now**.
3. **Co-browse**: set the masking rules, then tap **Start co-browse** to open a sample "Send money" form.

## SDK Configuration Flags

These flags are set on `AuviousConferenceConfiguration` before the conference view controller is created.

| Toggle | Config Property | Description |
|---|---|---|
| **Audio output to speaker** | `enableSpeaker` | Routes audio output to the device speaker instead of the earpiece. |
| **Background audio** | `backgroundAudioEnabled` | Keeps the audio session active when the app moves to the background. |
| **Camera** | `cameraAvailable` | Shows or hides the camera button during the call. |
| **Microphone** | `microphoneAvailable` | Shows or hides the microphone button during the call. |
| **Speaker** | `speakerAvailable` | Shows or hides the speaker button during the call. |
| **Picture in picture** | `pipAvailable` | Lets the call shrink into a floating window. |
| **Screen sharing** | `screenSharingAvailable` | Shows the screen share button. |
| **Allow AR pointer** | `arPointerAvailable` | Lets the agent point and draw on the camera or shared screen. |
| **Allow co-browse in the call** | `cobrowseAvailable` | Lets the agent ask to see the app during the call. |
| **Masking** | `cobrowseMasking`, `cobrowseShowsMaskHints` | Rules for the views that are blacked out for the agent (`AuviousMaskingRules`). |
