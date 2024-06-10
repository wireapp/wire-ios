# WireAnalytics
Provides access to Wire's analytics tools and trackers.

## Datadog
Datadog is a third-party analytics tool used opt-in for some builds. This Swift package ensures that the final app build does not contain any code or binaries from Datadog for privacy reasons by disabling full compilation.

To enable Datadog, set the environment variable `DATADOG_APP_ID`. This variable is already read during Xcode's Swift dependency resolution process, even before building.

### Set Up
- **CI**: Our CI tooling uses GitHub Actions and Fastlane to build the app. For builds that should include Datadog, set the `DATADOG_APP_ID` value.
- **Local Machine**: For debugging purposes, edit the `Package.swift` file and modify the line that reads `DATADOG_APP_ID`. Ensure you save the file and freshly resolve dependencies in Xcode.
