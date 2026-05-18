# Shared Kalium Auth Flow Test Notes

This branch wires the existing iOS authentication UI to the shared Kalium-backed auth ViewModel behind a developer flag. The legacy iOS auth flow remains the default path when the flag is off.

## Prerequisites

Build the KMP framework from the Android/KMP checkout:

```bash
cd ../wire-android-rc-ios-avs
./gradlew :shared:export-ios:linkDebugFrameworkIosSimulatorArm64
```

The iOS project currently links:

```text
../../wire-android-rc-ios-avs/shared/export-ios/build/bin/iosSimulatorArm64/debugFramework/WireIosShared.framework
```

The path is relative to `wire-ios/Wire-iOS.xcodeproj`. If your Android/KMP checkout is in a different sibling folder, either place it next to `wire-ios` under the expected name or relink `WireIosShared.framework` in Xcode.

## How To Enable

Run Wire with both developer flags enabled:

```text
--developer-flag=useWireAuthentication:true useKaliumSharedAuth:true
```

`useWireAuthentication` opens the new WireAuthentication module. `useKaliumSharedAuth` creates the shared KMP auth flow and passes it into the existing iOS auth UI.

With `useKaliumSharedAuth` off, the iOS UI uses the legacy login use cases.

## Flow To Test

1. Open the app with the flags above.
2. Start login from the unauthenticated screen.
3. Enter an email identifier.
4. Submit the password screen.
5. Confirm the logs contain:

```text
Using shared Kalium auth flow
Shared Kalium auth login succeeded, handing off to legacy auth
```

6. Confirm the app proceeds past the no-history / first-device screen and reaches the authenticated app.

For a negative smoke test, use invalid credentials. The shared ViewModel should return invalid credentials as state and the iOS UI should render the existing error.

## Code Pointers

- `wire-ios-utilities/Source/DeveloperFlag.swift`
  Defines `useKaliumSharedAuth`.

- `wire-ios/Wire-iOS/Sources/Authentication/AuthenticationInterfaceBuilder.swift`
  Checks the developer flag and creates `SharedAuthLoginFlowKMPGraph`.

- `wire-ios/Wire-iOS/Sources/KMPViewModel/Auth/SharedAuthLoginFlowKMPAdapter.swift`
  Adapts `WireIosShared.AuthLoginFlowIosViewModel` to the Swift `SharedAuthLoginFlowManaging` protocol.

- `WireAuthentication/Sources/WireAuthenticationAPI/SharedAuthLoginFlow.swift`
  Swift-side contract used by the UI module. This keeps WireAuthentication independent from Kotlin types.

- `WireAuthentication/Sources/WireAuthenticationUI/Views/DetermineAuthMethod/DetermineAuthMethodViewModel.swift`
  Sends identifier changes and submit intent to KMP when the shared flow is available.

- `WireAuthentication/Sources/WireAuthenticationUI/Views/Login/LoginViaEmail/LoginViaEmailViewModel.swift`
  Sends password changes and submit intent to KMP, observes KMP state/effects, and performs the temporary handoff to legacy auth storage on success.

- `wire-ios-sync-engine/Source/SessionManager/SessionManager.swift`
  Contains a temporary bridge that seeds the legacy self user id after shared auth success, gated by `useKaliumSharedAuth`.

## Temporary Bridge Details

On shared auth success, KMP returns tokens and user identity in `AuthLoginSuccessPayload`. iOS converts this payload into the existing `AuthenticationResult` shape so the current no-history and session loading code can keep running.

The bridge is intentionally temporary:

- it creates a synthetic `zuid` refresh cookie from the KMP refresh token;
- it sets a temporary expiry because legacy `ZMPersistentCookieStorage` treats a session as authenticated only when the `zuid` cookie has an expiry date;
- it seeds the legacy self user id so existing client registration can continue.

Search for `TODO: Remove with the temporary shared auth bridge` to find cleanup points.

## Legacy Safety

Legacy auth is still used when `useKaliumSharedAuth` is off. The KMP graph is not created, the shared flow is not passed into the WireAuthentication view models, and `LoginViaEmailViewModel` uses the existing iOS `LoginViaEmailUseCase`.
