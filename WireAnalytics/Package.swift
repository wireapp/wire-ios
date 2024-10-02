// swift-tools-version: 5.10

import Foundation
import PackageDescription

let package = Package(
    name: "WireAnalytics",
    platforms: [.iOS(.v15), .macOS(.v12)],
    products: [
        .library(name: "WireAnalytics", targets: ["WireAnalytics"]),
        .library(name: "WireDatadog", targets: ["WireDatadog"])
    ],
    dependencies: [
        .package(url: "https://github.com/DataDog/dd-sdk-ios.git", exact: "2.17.0")
    ],
    targets: [
        .target(
            name: "WireAnalytics",
            dependencies: resolveWireAnalyticsDependencies()
        ),
        .target(
            name: "WireDatadog",
            dependencies: [
                .product(name: "DatadogCore", package: "dd-sdk-ios"),
                .product(name: "DatadogCrashReporting", package: "dd-sdk-ios"),
                .product(name: "DatadogLogs", package: "dd-sdk-ios"),
                .product(name: "DatadogRUM", package: "dd-sdk-ios"),
                .product(name: "DatadogTrace", package: "dd-sdk-ios")
            ]
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
