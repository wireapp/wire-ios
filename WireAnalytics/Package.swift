// swift-tools-version: 5.10

import Foundation
import PackageDescription

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
<<<<<<< HEAD
            dependencies: resolveWireAnalyticsDependencies()
=======
            dependencies: resolveWireAnalyticsDependencies() + [
                .product(name: "Countly", package: "countly-sdk-ios")
            ],
            swiftSettings: swiftSettings
>>>>>>> aba5b2dca4 (feat: analytics milestone 1 - WPB-8911 (#1825))
        ),
        .target(
            name: "WireDatadog",
            dependencies: [
                .product(name: "DatadogCore", package: "dd-sdk-ios"),
                .product(name: "DatadogCrashReporting", package: "dd-sdk-ios"),
                .product(name: "DatadogLogs", package: "dd-sdk-ios"),
                .product(name: "DatadogRUM", package: "dd-sdk-ios"),
                .product(name: "DatadogTrace", package: "dd-sdk-ios")
<<<<<<< HEAD
            ]
=======
            ],
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
>>>>>>> aba5b2dca4 (feat: analytics milestone 1 - WPB-8911 (#1825))
        )
    ]
)

func resolveWireAnalyticsDependencies() -> [Target.Dependency] {
    // You can enable/disable Datadog for debugging by overriding the boolean.
    if hasEnvironmentVariable("ENABLE_DATADOG", "true") {
        ["WireDatadog"]
    } else {
        []
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
    target.swiftSettings = [
        .enableUpcomingFeature("ExistentialAny"),
        .enableUpcomingFeature("GlobalConcurrency"),
        .enableExperimentalFeature("StrictConcurrency")
    ]
}
