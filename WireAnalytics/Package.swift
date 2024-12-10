// swift-tools-version: 6.0

import Foundation
import PackageDescription

// You can enable/disable Datadog for debugging by overriding the boolean.
let datadogEnabled = hasEnvironmentVariable("ENABLE_DATADOG", "true")

let package = Package(
    name: "WireAnalytics",
    platforms: [.iOS(.v16), .macOS(.v12)],
    products: [
        .library(name: "WireAnalytics", targets: ["WireAnalytics"]),
        .library(name: "WireDatadog", targets: ["WireDatadog"]),
        .library(name: "WireAnalyticsSupport", targets: ["WireAnalyticsSupport"])
    ],
    dependencies: [
        .package(url: "https://github.com/DataDog/dd-sdk-ios.git", exact: "2.18.0"),
        .package(url: "https://github.com/Countly/countly-sdk-ios.git", exact: "24.4.2"),
        .package(path: "../WireLogging"),
        .package(path: "../WirePlugins")
    ],
    targets: [
        .target(
            name: "WireAnalytics",
            dependencies: [
                .product(name: "Countly", package: "countly-sdk-ios"),
                "WireLogging"
            ]
        ),
        .target(
            name: "WireDatadog",
            dependencies: datadogDependencies() + ["WireLogging"],
            path: "Sources/WireDatadog",
            sources: datadogFiles()
        ),
        .target(
            name: "WireAnalyticsSupport",
            dependencies: ["WireAnalytics"],
            plugins: [
                .plugin(name: "SourceryPlugin", package: "WirePlugins")
            ]
        ),
        .testTarget(
            name: "WireAnalyticsTests",
            dependencies: ["WireAnalytics", "WireAnalyticsSupport"]
        )
    ]
)

func datadogDependencies() -> [Target.Dependency] {
    guard datadogEnabled else {
        // note: in this case SPM will warn that the dd-sdk-ios is not used
        return []
    }
    return [
        .product(name: "DatadogCore", package: "dd-sdk-ios"),
        .product(name: "DatadogCrashReporting", package: "dd-sdk-ios"),
        .product(name: "DatadogLogs", package: "dd-sdk-ios"),
        .product(name: "DatadogRUM", package: "dd-sdk-ios"),
        .product(name: "DatadogTrace", package: "dd-sdk-ios")
    ]
}

func datadogFiles() -> [String] {
    if datadogEnabled {
        ["WireDatadog.swift", "LogLevel.swift"]
    } else {
        ["WireFakeDatadog.swift", "LogLevel.swift"]
    }
}

func hasEnvironmentVariable(_ name: String, _ value: String? = nil) -> Bool {
    if let value {
        ProcessInfo.processInfo.environment[name] == value
    } else {
        ProcessInfo.processInfo.environment[name] != nil
    }
}

for target in package.targets {
    target.swiftSettings = (target.swiftSettings ?? []) + [
        .enableUpcomingFeature("InternalImportsByDefault"),
        .enableUpcomingFeature("FullTypedThrows"),
        .enableUpcomingFeature("ExistentialAny")
    ]
}
