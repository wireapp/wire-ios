// swift-tools-version: 6.0

import Foundation
import PackageDescription

// You can enable/disable Datadog for debugging by overriding the boolean.
let isDatadogEnabled = hasEnvironmentVariable("ENABLE_DATADOG", "true")
let isCountlyEnabled = hasEnvironmentVariable("ENABLE_COUNTLY", "true")

let package = Package(
    name: "WireAnalytics",
    platforms: [.iOS("16.4"), .macOS(.v12)],
    products: [
        .library(name: "WireAnalytics", targets: ["WireAnalytics"]),
        .library(name: "WireAnalyticsSupport", targets: ["WireAnalyticsSupport"]),
        .library(name: "WireCountly", targets: ["WireCountly"]),
        .library(name: "WireDatadog", targets: ["WireDatadog"])
    ],
    dependencies: [
        .package(url: "https://github.com/Countly/countly-sdk-ios.git", exact: "25.4.3"),
        .package(url: "https://github.com/DataDog/dd-sdk-ios.git", exact: "2.27.0"),
        .package(path: "../WireFoundation"),
        .package(path: "../WireLogging"),
        .package(path: "../WirePlugins")
    ],
    targets: [
        .target(
            name: "WireAnalytics",
            dependencies: [
                "WireFoundation",
                "WireLogging",
                .product(name: "WireLegacyLogging", package: "WireLogging")
            ]
        ),
        .target(
            name: "WireAnalyticsSupport",
            dependencies: ["WireAnalytics", "WireFoundation"],
            plugins: [.plugin(name: "SourceryPlugin", package: "WirePlugins")]
        ),
        .testTarget(
            name: "WireAnalyticsTests",
            dependencies: ["WireAnalytics", "WireAnalyticsSupport", "WireFoundation"]
        ),

        .target(
            name: "WireCountly",
            dependencies: countlyDependencies() + ["WireAnalytics"],
            sources: countlyFiles()
        ),

        .target(
            name: "WireDatadog",
            dependencies: datadogDependencies() + [
                "WireLogging",
                .product(name: "WireLegacyLogging", package: "WireLogging")
            ],
            sources: datadogFiles()
        ),

        // This target prevents warnings about `countly-sdk-ios` or `dd-sdk-ios` not being used.
        .target(
            name: "WarningPrevention",
            dependencies: [
                .product(name: "Countly", package: "countly-sdk-ios"),
                .product(name: "DatadogCore", package: "dd-sdk-ios")
            ]
        )
    ]
)

// MARK: - Countly

func countlyDependencies() -> [Target.Dependency] {
    guard isCountlyEnabled else {
        return []
    }
    return [
        .product(name: "Countly", package: "countly-sdk-ios")
    ]
}

func countlyFiles() -> [String] {
    if isCountlyEnabled {
        ["CountlyWrapper.swift"]
    } else {
        ["CountlyDummy.swift"]
    }
}

// MARK: - Datadog

func datadogDependencies() -> [Target.Dependency] {
    guard isDatadogEnabled else {
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
    if isDatadogEnabled {
        ["WireDatadog.swift", "WireLegacyLogging.swift"]
    } else {
        ["WireFakeDatadog.swift", "WireLegacyLogging.swift"]
    }
}

// MARK: -

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
        .enableUpcomingFeature("ExistentialAny")
    ]
}
