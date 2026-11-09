# Auvious iOS SDK Examples

This repository contains an example of how to use the Auvious iOS SDK in an iOS project.

## Example projects
- [SimpleConference](SimpleConference) is a quick example of how to join a video call given a ticket, with SwiftUI

- ~~[GenesysCloudSimpleConference](GenesysCloudSimpleConference)~~ [DEPRECATED] is a quick example of how to initiate a video call using the webchat channel on GenesysCloud. 

**[UPDATE]. WebChat is no longer supported by Genesys**


To use the AuviousSDK in your project, follow these steps:

## Installation

AuviousSDK is available through as a [CocoaPod](https://cocoapods.org). You can install it using one of the following ways:

- Auvious Cocoa Pods Repo. Add the following sources to your Podfile
  ```ruby
  source 'https://github.com/auvious/CocoaPodSpecs.git'
  ```
  Make sure you also include the official CocoaPods repo source or a valid mirror of it
  ```ruby
  source 'https://cdn.cocoapods.org/'
  ```
  Last but not least, you need to add the AuviousSDK pod on all targets that will need it
  ```ruby
  pod 'AuviousSDK', '1.5.0'
  ```
- Auvious SDK github repo. This method only requires the following line on the target dependencies:
  ```ruby
  pod 'AuviousSDK', :git => 'https://github.com/auvious/auvious-sdk-ios.git', :tag => '1.5.0'
  ```

Next you need to run `pod install` in order for AuviousSDK and it's dependencies to be installed in the project workspace.

Finally you'll need disable bitcode in 'Build Settings' and also add NSMicrophoneUsageDescription,NSCameraUsageDescription texts in Info.plist.

---

## Setup Instructions

### 1. Info.plist Permissions

Add the following keys to your `Info.plist` to request camera and microphone access:

```xml
<key>NSCameraUsageDescription</key>
<string>Camera access is required for video calls.</string>
<key>NSMicrophoneUsageDescription</key>
<string>Microphone access is required for audio calls.</string>
```

### 2. Build Settings

Disable Bitcode in your target's **Build Settings**:

- Navigate to **Build Settings → Enable Bitcode** and set it to **No**.

### 3. Background Audio (Optional)

If you want audio to continue when the app goes to the background, add the audio background mode to your `Info.plist`:

```xml
<key>UIBackgroundModes</key>
<array>
    <string>audio</string>
</array>
```

Then enable it in the SDK configuration (see `backgroundAudioEnabled` below).

### 4. App Lifecycle Hooks

The SDK needs to be notified when the app moves between foreground and background. Add the following calls in your `AppDelegate` or `SceneDelegate`:

```swift
import AuviousSDK

// In applicationDidEnterBackground / sceneDidEnterBackground
AuviousConferenceSDK.sharedInstance.onApplicationPause()

// In applicationWillEnterForeground / sceneWillEnterForeground
AuviousConferenceSDK.sharedInstance.onApplicationResume()
```

---

## Usage Example

### Simple Conference (Recommended)

The easiest way to add a conference to your app is using the built-in `AuviousConferenceVCNew` view controller.

```swift
import AuviousSDK

class ViewController: UIViewController {

    func joinConference() {
        // 1. Build the configuration
        let config = AuviousConferenceConfiguration()
        config.username = "<ticket>" // set the auvious ticket
        config.baseEndpoint = "https://auvious.video/"
        config.mqttEndpoint = "auvious.video"

        // 2. Set call mode
        config.callMode = .audioVideo

        // 3. (Optional) Customize the UI
        config.conferenceBackgroundColor = .black
        config.cameraAvailable = true
        config.microphoneAvailable = true
        config.speakerAvailable = true
        config.pipAvailable = true
        config.screenSharingAvailable = false
        config.backgroundAudioEnabled = false

        // 4. Present the conference view controller
        let conferenceVC = AuviousConferenceVCNew(configuration: config, delegate: self)
        present(conferenceVC, animated: true)
    }
}

// MARK: - AuviousSimpleConferenceDelegate

extension ViewController: AuviousSimpleConferenceDelegate {

    func onConferenceSuccess() {
        // Called when the conference ends normally
        print("Conference ended successfully")
    }

    func onConferenceError(_ error: AuviousSDKGenericError) {
        // Called on error (authentication failure, network issues, etc.)
        switch error {
        case .AUTHENTICATION_FAILURE:
            print("Authentication failed — check credentials")
        case .NETWORK_ERROR:
            print("Network error")
        case .PERMISSION_REQUIRED:
            print("Camera or microphone permission denied")
        case .INVALID_TICKET(let ticketId):
            print("Invalid ticket: \(ticketId)")
        default:
            print("Conference error: \(error)")
        }
    }
}
```

### Low-Level Conference API

For full control over the conference flow and UI, use `AuviousConferenceSDK` directly.

```swift
import AuviousSDK

class ConferenceManager: AuviousSDKConferenceDelegate {

    func setup() {
        AuviousConferenceSDK.sharedInstance.delegate = self

        // Configure the SDK
        AuviousConferenceSDK.sharedInstance.configure(
            params: [:],
            username: "<ticket>",
            password: "<password>",
            name: nil,
            clientId: "<client-id>",
            baseEndpoint: "https://auvious.video/",
            mqttEndpoint: "auvious.video"
        )

        // Log in
        AuviousConferenceSDK.sharedInstance.login(
            onLoginSuccess: { [weak self] endpoint in
                self?.joinConference()
            },
            onLoginFailure: { error in
                print("Login failed: \(error)")
            }
        )
    }

    func joinConference() {
        AuviousConferenceSDK.sharedInstance.joinConference(
            conferenceId: "<conference-name>",
            onSuccess: { [weak self] conference in
                // Start publishing local audio/video
                self?.publishLocalStream()
            },
            onFailure: { error in
                print("Failed to join: \(error)")
            }
        )
    }

    func publishLocalStream() {
        AuviousConferenceSDK.sharedInstance.startPublishLocalStreamFlow(type: .micAndCam)
    }

    func leaveConference() {
        AuviousConferenceSDK.sharedInstance.leaveConference(
            conferenceId: "<conference-name>",
            onSuccess: { },
            onFailure: { _ in }
        )
    }

    // MARK: - AuviousSDKConferenceDelegate

    func auviousSDK(didReceiveLocalVideoTrack localVideoTrack: RTCVideoTrack!) {
        // Render the local video track in your UI
    }

    func auviousSDK(didReceiveRemoteStream stream: RTCMediaStream, streamId: String,
                    endpointId: String, type: StreamType) {
        // Render the incoming remote stream in your UI
    }

    func auviousSDK(didReceiveLocalStream stream: RTCMediaStream, streamId: String,
                    type: StreamType) {
        // Local stream is ready
    }

    func auviousSDK(onError error: AuviousSDKError) {
        print("SDK error: \(error)")
    }

    func auviousSDK(didChangeState newState: StreamEventState, streamId: String,
                    streamType: StreamType, endpointId: String) {
        // React to stream state transitions (connecting, connected, disconnected, etc.)
    }

    func auviousSDK(trackMuted type: StreamType, endpointId: String) { }
    func auviousSDK(trackUnmuted type: StreamType, endpointId: String) { }
    func auviousSDK(conferenceOnHold flag: Bool) { }
    func auviousSDK(didReceiveConferenceEvent event: ConferenceEvent) { }
    func auviousSDK(didRejoinConference conference: ConferenceSimpleView) { }
    func auviousSDK(recorderStateChanged toActive: Bool) { }
    func auviousSDK(agentPortraitMode flag: Bool, endpointId: String) { }
    func auviousSDK(screenSharingStarted: Bool) { }
    func auviousSDK(screenSharingStopped: Bool) { }
    func auviousSDK(didResumeFromBackground withActiveAudio: Bool) { }
}
```

---

## Mobile Co-browse

Co-browse lets the customer share this app's screen with an agent, without a video call. Both sides can draw on the shared
screen, and sensitive views are sent as black boxes. The session UI lives in its own window above the app, so the customer
can keep navigating while sharing.

### Start a session

The agent creates a co-browse ticket (PIN) and gives it to the customer. Start the session with that ticket, from the main thread:

```swift
import AuviousSDK

var config = AuviousCobrowseConfiguration(ticket: pin,                       // the PIN created by the agent
                                          baseEndpoint: "https://auvious.video/",
                                          mqttEndpoint: "auvious.video")
config.participantName = "Jane"                                             // optional
config.masking.accessibilityIdentifiers = ["payment.iban", "card.*"]        // exact ids, or prefixes ending with *

AuviousCobrowse.shared.start(configuration: config, delegate: self)
```

The SDK redeems the ticket, joins the agent's room and asks the customer to share the screen: a short explanation sheet,
then the iOS screen recording prompt. The customer ends the session with the End button; the app can end it with
`AuviousCobrowse.shared.stop()`.

Session updates arrive on the main thread; all methods are optional:

```swift
extension MyViewController: AuviousCobrowseDelegate {
    func cobrowse(didChangeState state: AuviousCobrowseState) { }   // connecting, awaitingConsent, sharing, notSharing, ...
    func cobrowseDidEnd(reason: AuviousCobrowseEndReason) { }       // customerEnded, agentEnded, failed
    func cobrowse(didFailWith error: AuviousSDKGenericError) { }
}
```

### Portrait while sharing

Co-browse is portrait only: rotating while the screen is shared stalls it on the agent's side. Return the SDK's orientations
from your app delegate, so the app rotates to portrait when a session starts and back when it ends:

```swift
func application(_ application: UIApplication, supportedInterfaceOrientationsFor window: UIWindow?) -> UIInterfaceOrientationMask {
    return AuviousCobrowse.shared.supportedInterfaceOrientations(otherwise: .allButUpsideDown)
}
```

### Masking

`AuviousMaskingRules` decides which views are blacked out. The whole frame of a masked view is covered, so mask the field,
not the form.

| Property                   | Type             | Default | Description                                                                        |
| -------------------------- | ---------------- | ------- | ---------------------------------------------------------------------------------- |
| `accessibilityIdentifiers` | `Set<String>`    | `[]`    | Exact identifiers, or prefixes ending with `*` (e.g. `"card.*"`).                  |
| `viewClasses`              | `[UIView.Type]`  | `[]`    | View classes to mask, subclasses included.                                         |
| `maskSecureTextFields`     | `Bool`           | `true`  | Mask password fields, and the keyboard while one is being edited.                  |
| `maskAllTextInputs`        | `Bool`           | `false` | Mask every `UITextField` and `UITextView` unless marked `auviousMasked = false`.   |

Views can also be marked directly:

```swift
cardNumberField.auviousMasked = true                 // always masked; false never masks it
Text(iban).auviousMasked()                           // SwiftUI

AuviousCobrowse.shared.maskingRules = rules          // change the rules at any time, also while sharing
AuviousCobrowse.shared.debugHighlightMasks = true    // outline masked regions on the device to check your rules
```

### AuviousCobrowseConfiguration

| Property              | Type                  | Default      | Description                                                                |
| --------------------- | --------------------- | ------------ | -------------------------------------------------------------------------- |
| `ticket`              | `String`              | —            | The co-browse ticket (PIN) created by the agent.                           |
| `baseEndpoint`        | `String`              | —            | Base URL of the Auvious API (e.g. `"https://auvious.video/"`).             |
| `mqttEndpoint`        | `String`              | —            | Hostname of the MQTT broker (e.g. `"auvious.video"`).                      |
| `clientId`            | `String`              | `"customer"` | OAuth client id.                                                           |
| `participantName`     | `String?`             | `nil`        | Name shown to the agent.                                                   |
| `customerMetadata`    | `[String: Any]?`      | `nil`        | Metadata sent to the agent with the join request.                          |
| `showsShareExplainer` | `Bool`                | `true`       | Show a short explanation before the iOS screen recording prompt.           |
| `annotationsEnabled`  | `Bool`                | `true`       | Let the customer draw, and show the agent's drawings.                      |
| `masking`             | `AuviousMaskingRules` | empty rules  | Which views are blacked out.                                               |
| `showsMaskHints`      | `Bool`                | `true`       | Outline masked views on the customer's screen.                             |
| `accentColor`         | `UIColor`             | Auvious red  | Color of the sharing border, status pill and End button.                   |

### Co-browse during a video call

Only one co-browse session runs at a time, and not alongside `AuviousConferenceVCNew`. To let the agent ask to co-browse
during a call, set `cobrowseAvailable` on `AuviousConferenceConfiguration` (see [Co-browse & AR Pointer](#co-browse--ar-pointer)).
While sharing, the call shrinks to picture-in-picture and the agent doesn't see it.

See [`CobrowseDemoViewController`](SimpleConference/SimpleConference/CobrowseDemoViewController.swift) in the example app for a
sample screen that starts a session and uses masking.

---

## Configuration Options Reference

### AuviousConferenceConfiguration

Used when presenting `AuviousConferenceVCNew` for the built-in conference UI.

#### Authentication & Connection

| Property       | Type     | Description                                                          |
| -------------- | -------- | -------------------------------------------------------------------- |
| `username`     | `String` | Username (or ticket) used to authenticate with the Auvious platform. |
| `password`     | `String` | Password used to authenticate.                                       |
| `grantType`    | `String` | OAuth grant type. Default: `"password"`.                             |
| `clientId`     | `String` | Client identifier registered on the Auvious platform. Default: `"customer"`               |
| `conference`   | `String` | Name of the conference room to join or create.                       |
| `baseEndpoint` | `String` | Base URL of the Auvious API (e.g. `"https://auvious.video/"`).       |
| `mqttEndpoint` | `String` | Hostname of the MQTT WebSocket broker (e.g. `"auvious.video"`).      |

#### Call Behaviour

| Property                 | Type              | Default       | Description                                                                                                     |
| ------------------------ | ----------------- | ------------- | --------------------------------------------------------------------------------------------------------------- |
| `callMode`               | `AuviousCallMode` | `.audioVideo` | Stream mode for the call. Use `.audio` for audio-only, `.video` for video-only, or `.audioVideo` for both.      |
| `enableSpeaker`          | `Bool`            | `true`        | Route audio to the loudspeaker on join.                                                                         |
| `backgroundAudioEnabled` | `Bool`            | `false`       | Keep audio running when the app moves to the background. Requires the `audio` UIBackgroundMode in `Info.plist`. |
| `participantName`        | `String?`         | `nil`         | Optional display name shown to other participants.                                                              |

#### UI Controls

| Property                    | Type      | Default     | Description                               |
| --------------------------- | --------- | ----------- | ----------------------------------------- |
| `conferenceBackgroundColor` | `UIColor` | `.darkGray` | Background colour of the conference view. |
| `cameraAvailable`           | `Bool`    | `true`      | Show the camera toggle button.            |
| `microphoneAvailable`       | `Bool`    | `true`      | Show the microphone mute/unmute button.   |
| `speakerAvailable`          | `Bool`    | `true`      | Show the speaker toggle button.           |
| `pipAvailable`              | `Bool`    | `true`      | Show the Picture-in-Picture button.       |
| `screenSharingAvailable`    | `Bool`    | `true`      | Show the screen-sharing button.           |

#### Co-browse & AR Pointer

| Property                      | Type                  | Default     | Description                                                                                                            |
| ----------------------------- | --------------------- | ----------- | ---------------------------------------------------------------------------------------------------------------------- |
| `cobrowseAvailable`           | `Bool`                | `false`     | Let the agent ask to co-browse the app during the call. The call shrinks to picture-in-picture while sharing.          |
| `cobrowseMasking`             | `AuviousMaskingRules` | empty rules | Which views are blacked out in the co-browse screen share.                                                             |
| `cobrowseAnnotationsEnabled`  | `Bool`                | `true`      | Let the customer draw on the shared screen, and show the agent's drawings.                                             |
| `cobrowseShowsMaskHints`      | `Bool`                | `true`      | Outline masked views on the customer's screen.                                                                         |
| `cobrowseShowsShareExplainer` | `Bool`                | `true`      | Show a short explanation before the iOS screen recording prompt.                                                       |
| `arPointerAvailable`          | `Bool`                | `true`      | Let the agent point and draw on the customer's camera and screen share; the customer can draw back.                    |

---

### AuviousConferenceSDK — Key Properties

| Property                 | Type                            | Description                                                                                    |
| ------------------------ | ------------------------------- | ---------------------------------------------------------------------------------------------- |
| `delegate`               | `AuviousSDKConferenceDelegate?` | Receives stream, state, and error events.                                                      |
| `publishVideoResolution` | `PublishVideoResolution`        | Video quality for the outgoing stream. `.min` (640×480), `.mid` (960×720), `.max` (1920×1080). |
| `isLoggedIn`             | `Bool`                          | Whether the SDK is currently authenticated. Read-only.                                         |
| `userEndpointId`         | `String?`                       | The current user's endpoint identifier. Read-only.                                             |

---

### AuviousDiagnostics — Error Reporting & Logging

Set these before using the SDK, e.g. in `application(_:didFinishLaunchingWithOptions:)`. Same settings as the Android SDK.

```swift
AuviousDiagnostics.errorReporting = .custom(dsn: "https://<key>@<your-sentry>/<project>") // .auvious (default), .disabled
AuviousDiagnostics.logLevel = .minimal                                                  // .minimal (default), .full
AuviousDiagnostics.consoleLogLevel = .error
```

| Property          | Type                     | Default    | Description                                                                                                                         |
| ----------------- | ------------------------ | ---------- | ----------------------------------------------------------------------------------------------------------------------------------- |
| `errorReporting`  | `AuviousErrorReporting`  | `.auvious` | Where Sentry reports go: `.auvious`, `.custom(dsn:)` (your own Sentry) or `.disabled`.                                               |
| `logLevel`        | `AuviousLogLevel`        | `.minimal` | What goes to Sentry. `.minimal`: crashes in the SDK, with its error logs as breadcrumbs. `.full`: also the SDK's errors as events and all its logs as breadcrumbs. |
| `consoleLogLevel` | `AuviousConsoleLogLevel` | `.warning` | SDK console logs at this level or above: `.none`, `.error`, `.warning`, `.info`, `.debug`.                                           |

Only crashes with a frame in the SDK's code (AuviousSDK, WebRTC) are reported, not the rest of the app's crashes. Reporting
starts when the SDK is first used; a crash is sent the next time the app uses the SDK.

If your app uses Sentry, start it before using the SDK. The SDK then leaves your Sentry as it is, sends its reports through a
client of its own and catches no crashes. Otherwise the SDK starts Sentry itself to catch crashes, with everything else of
Sentry's (sessions, app hangs, network and UI tracking) off.

---

### Enumerations

#### AuviousCallMode

| Value         | Description           |
| ------------- | --------------------- |
| `.audio`      | Audio-only call.      |
| `.video`      | Video-only call.      |
| `.audioVideo` | Audio and video call. |

#### StreamType

| Value        | Description             |
| ------------ | ----------------------- |
| `.mic`       | Audio stream only.      |
| `.cam`       | Video stream only.      |
| `.micAndCam` | Audio and video stream. |
| `.screen`    | Screen-sharing stream.  |

#### PublishVideoResolution

| Value  | Resolution  |
| ------ | ----------- |
| `.min` | 640 × 480   |
| `.mid` | 960 × 720   |
| `.max` | 1920 × 1080 |

#### AuviousSDKGenericError

| Value                       | Description                                             |
| --------------------------- | ------------------------------------------------------- |
| `.AUTHENTICATION_FAILURE`   | Credentials were rejected by the platform.              |
| `.PERMISSION_REQUIRED`      | Camera or microphone permission was denied by the user. |
| `.NETWORK_ERROR`            | A network-level failure occurred.                       |
| `.CALL_REJECTED`            | The call was rejected by the remote party.              |
| `.CONFERENCE_MISSING`       | The specified conference room does not exist.           |
| `.INVALID_TICKET(ticketId)` | The provided ticket is invalid or expired.              |
| `.UNKNOWN_FAILURE`          | An unexpected error occurred.                           |

---

---

## What's new in 1.5.0

- **Mobile co-browse** - `AuviousCobrowse` shares the app's screen with an agent, without a call or from within one. Sensitive views are masked, and both sides can draw on the shared screen
- **AR pointer** - the agent can point and draw on the customer's camera and screen share
- **Network recovery** - the call's streams and MQTT connection recover after a network drop, and missed conference events are caught up
- **Conference UI** - placeholder tiles for participants without video, tap a remote video to switch between fit and fill, pinch to zoom a shared screen
- **Error reporting** - `AuviousDiagnostics`: Sentry reports go to Auvious by default, to your own project with `.custom(dsn:)`, or nowhere with `.disabled`. Only crashes in the SDK's code are reported. `consoleLogLevel` sets the SDK's console logs (default `.warning`). The app no longer needs to start Sentry itself
- **Requirements** - iOS 15, WebRTC M155 (Unified Plan), Metal video views
