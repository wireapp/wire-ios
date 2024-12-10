// swift-tools-version: 6.0

import Foundation
import PackageDescription

// You can enable/disable Datadog for debugging by overriding the boolean.
let isDatadogEnabled = hasEnvironmentVariable("ENABLE_DATADOG", "true")
let isCountlyEnabled = true // TODO: [WPB-11285] use env variable to set

let package = Package(
    name: "WireAnalytics",
    platforms: [.iOS(.v16), .macOS(.v12)],
    products: [
        .library(name: "WireAnalytics", targets: ["WireAnalytics"]),
        .library(name: "WireAnalyticsSupport", targets: ["WireAnalyticsSupport"]),
        .library(name: "WireCountly", targets: ["WireCountly"]),
        .library(name: "WireDatadog", targets: ["WireDatadog"]),
        .library(name: "WireAnalyticsDummy", targets: ["WarningPrevention"]) // don't use
    ],
    dependencies: [
        .package(url: "https://github.com/Countly/countly-sdk-ios.git", exact: "24.4.2"),
        .package(url: "https://github.com/DataDog/dd-sdk-ios.git", exact: "2.18.0"),
        .package(path: "../WireLogging"),
        .package(path: "../WirePlugins")
    ],
    targets: [
        .target(
            name: "WireAnalytics",
            dependencies: ["WireLogging"]
        ),
        .target(
            name: "WireAnalyticsSupport",
            dependencies: ["WireAnalytics"],
            plugins: [.plugin(name: "SourceryPlugin", package: "WirePlugins")]
        ),
        .testTarget(
            name: "WireAnalyticsTests",
            dependencies: ["WireAnalytics", "WireAnalyticsSupport"]
        ),

        .target(
            name: "WireCountly",
            dependencies: countlyDependencies() + ["WireAnalytics"],
            sources: countlyFiles()
        ),

        .target(
            name: "WireDatadog",
            dependencies: datadogDependencies() + ["WireLogging"],
            sources: datadogFiles()
        ),

        // This target prevents warnings saying countly-sdk-ios or dd-sdk-ios are not used.
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
        ["WireDatadog.swift"]
    } else {
        ["WireFakeDatadog.swift"]
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
        .enableUpcomingFeature("FullTypedThrows"),
        .enableUpcomingFeature("ExistentialAny")
    ]
}
