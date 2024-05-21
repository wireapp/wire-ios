# Wire™

[![Wire logo](https://github.com/wireapp/wire/blob/master/assets/header-small.png?raw=true)](https://wire.com/jobs/)

This repository is part of the source code of Wire. You can find more information at [wire.com](https://wire.com) or by contacting opensource@wire.com.

You can find the published source code at [github.com/wireapp/wire](https://github.com/wireapp/wire).

For licensing information, see the attached LICENSE file and the list of third-party licenses at [wire.com/legal/licenses/](https://wire.com/legal/licenses/).

If you compile the open source software that we make available from time to time to develop your own mobile, desktop or web application, and cause that application to connect to our servers for any purposes, we refer to that resulting application as an “Open Source App”.  All Open Source Apps are subject to, and may only be used and/or commercialized in accordance with, the Terms of Use applicable to the Wire Application, which can be found at https://wire.com/legal/#terms.  Additionally, if you choose to build an Open Source App, certain restrictions apply, as follows:

a. You agree not to change the way the Open Source App connects and interacts with our servers; b. You agree not to weaken any of the security features of the Open Source App; c. You agree not to use our servers to store data for purposes other than the intended and original functionality of the Open Source App; d. You acknowledge that you are solely responsible for any and all updates to your Open Source App.

For clarity, if you compile the open source software that we make available from time to time to develop your own mobile, desktop or web application, and do not cause that application to connect to our servers for any purposes, then that application will not be deemed an Open Source App and the foregoing will not apply to that application.

No license is granted to the Wire trademark and its associated logos, all of which will continue to be owned exclusively by Wire Swiss GmbH. Any use of the Wire trademark and/or its associated logos is expressly prohibited without the express prior written consent of Wire Swiss GmbH.


# Wire iOS

The Wire mobile app has an architectural layer that we call *sync engine*. It is the client-side layer that processes all the data that is displayed in the mobile app. It handles network communication and authentication with the backend, push notifications, local caching of data, client-side business logic, signaling with the audio-video libraries, encryption and decryption (using encryption libraries from a lower level) and other bits and pieces.

The user interface layer of the mobile app is built on top of the *sync engine*, which provides the data to display to the UI.
The sync engine itself is built on top of a few third-party frameworks, and uses Wire components that are shared between platforms for cryptography (Proteus/Cryptobox) and audio-video signaling (AVS).

![Mobile app architecture](https://github.com/wireapp/wire/blob/master/assets/mobile-architecture.png?raw=true)


## How to Build the Open Source Client

### What's Included in the Open Source Client

This repository contains the Wire iOS client project. You can build the project yourself, but note the following differences compared to the binary Wire iOS client available on the App Store:
- The open source project does not include API keys for third-party services.
- The open source project links against the open source Wire audio-video-signaling (AVS) library. The binary App Store client links against an AVS version that includes proprietary improvements for call quality.

### Prerequisites

To build Wire for iOS locally, ensure the following tools are installed and set up on your machine:

- [Xcode 15.4](https://xcodereleases.com)
- [Carthage 0.39.1 or newer](https://github.com/Carthage/Carthage)
- Ruby environment without admin permissions, which can be set up using [rbenv](https://github.com/rbenv/rbenv). Install the Ruby version specific in the [`Gemfile`](Gemfile) and set it as the global version.
- SSH key for Git. Follow these guides to [generate a new SSH key and add it locally](https://docs.github.com/en/authentication/connecting-to-github-with-ssh/generating-a-new-ssh-key-and-adding-it-to-the-ssh-agent) and [add it to GitHub](https://docs.github.com/en/authentication/connecting-to-github-with-ssh/adding-a-new-ssh-key-to-your-github-account).

The setup script will automatically verify that these requirements are met.

### How to Build Locally

1. Clone the `wire-ios-mono` repository.
2. From the cloned directory, run `./setup.sh`. This script will pull in all necessary dependencies with Carthage and verify the tool versions.
3. Open the project `wire-ios-mono.xcworkspace` in Xcode.
4. Ensure the `Wire-iOS` app scheme is selected.
5. Click the "Run" button in Xcode.

These steps build the Wire umbrella project, pulling in all other Wire frameworks with Carthage. To modify or debug other Wire frameworks, navigate to the `Carthage/Checkouts` subfolder and open the individual projects for each dependency.

To rebuild a dependency and use it in the umbrella project, run:

```sh
carthage bootstrap --platform ios --use-xcframeworks
```

### Known Limitations

Notifications sent through the Apple Push Notification service can only be received by the App Store Wire client, which is code-signed with Wire's own certificate. This is a security feature enforced by Apple, as documented in Apple's [Local and Remote Notification Programming Guide](https://developer.apple.com/library/content/documentation/NetworkingInternet/Conceptual/RemoteNotificationsPG/). Any client built from source will not be able to receive notifications.

### Translations

All Wire translations are crowdsourced via CrowdIn. You can contribute to the translations at [CrowdIn](https://crowdin.com/projects/wire).

### Running Security Tests

To run all security tests, you first need to be able to build the app locally. Refer to the "How to Build Locally" section above. Once the app is built, you can run the security tests from the command line with the following commands:

```sh
xcodebuild test \
  -workspace wire-ios-mono.xcworkspace \
  -scheme Wire-iOS \
  -testPlan SecurityTests \
  -destination 'platform=iOS Simulator,name=iPhone 14,OS=17.4'

xcodebuild test \
  -workspace wire-ios-mono.xcworkspace \
  -scheme WireSyncEngine \
  -testPlan SecurityTests \
  -destination 'platform=iOS Simulator,name=iPhone 14,OS=17.4'

xcodebuild test \
  -workspace wire-ios-mono.xcworkspace \
  -scheme WireDataModel \
  -testPlan SecurityTests \
  -destination 'platform=iOS Simulator,name=iPhone 14,OS=17.4'
```

`xcodebuild` will print the test results to the console. It will also log the location of the test results (in `.xcresult` format), which you can open with Xcode to see the test results in a more user-friendly format.
