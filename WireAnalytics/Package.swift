// swift-tools-version: 5.10

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
        .package(path: "../SourceryPlugin")
    ],
    targets: [
        .target(
            name: "WireAnalytics",
            dependencies: [
                .product(name: "Countly", package: "countly-sdk-ios"),
            ],
            swiftSettings: swiftSettings
        ),
        .target(
            name: "WireDatadog",
            dependencies: datadogDependencies(),
            path: "Sources/WireDatadog",
            exclude: ["WireFakeDatadog.swift"],
            sources: datadogFiles(),
            swiftSettings: swiftSettings
        ),
        .target(
            name: "WireAnalyticsSupport",
            dependencies: ["WireAnalytics"],
            plugins: [
                .plugin(
                    name: "SourceryPlugin",
                    package: "SourceryPlugin"
                )
            ]
        ),
        .testTarget(
            name: "WireAnalyticsTests",
            dependencies: ["WireAnalytics", "WireAnalyticsSupport"]
        )
    ]
)

func datadogDependencies() -> [Target.Dependency] {
    if datadogEnabled {
        [
            .product(name: "DatadogCore", package: "dd-sdk-ios"),
            .product(name: "DatadogCrashReporting", package: "dd-sdk-ios"),
            .product(name: "DatadogLogs", package: "dd-sdk-ios"),
            .product(name: "DatadogRUM", package: "dd-sdk-ios"),
            .product(name: "DatadogTrace", package: "dd-sdk-ios")
        ]
    } else {
        []
    }
}

func datadogFiles() -> [String] {
    if datadogEnabled {
        ["WireDatadog.swift"]
    } else {
        ["WireFakeDatadog.swift"]
    }
}

func hasEnvironmentVariable(_ name: String, _ value: String? = nil) -> Bool {
    if let value {
        ProcessInfo.processInfo.environment[name] == value
    } else {
        ProcessInfo.processInfo.environment[name] != nil
    }
}

let swiftSettings: [SwiftSetting] = [
    .enableUpcomingFeature("ExistentialAny"),
    .enableUpcomingFeature("GlobalConcurrency"),
    .enableExperimentalFeature("StrictConcurrency")
]
