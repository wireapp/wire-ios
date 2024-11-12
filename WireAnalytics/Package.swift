// swift-tools-version: 5.10

import Foundation
import PackageDescription

let isDatadogEnabled = ProcessInfo.processInfo.environment["ENABLE_DATADOG"] == "true"

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
                .product(name: "Countly", package: "countly-sdk-ios")
            ]
        ),
        .target(
            name: "WireDatadog",
            dependencies: isDatadogEnabled ? [
                .product(name: "DatadogCore", package: "dd-sdk-ios"),
                .product(name: "DatadogCrashReporting", package: "dd-sdk-ios"),
                .product(name: "DatadogLogs", package: "dd-sdk-ios"),
                .product(name: "DatadogRUM", package: "dd-sdk-ios"),
                .product(name: "DatadogTrace", package: "dd-sdk-ios")
            ] : []
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
            dependencies: [
                "WireAnalytics",
                "WireAnalyticsSupport"
            ] + (
                // adding this line fixes the warning that "dd-sdk-ios" is not used
                isDatadogEnabled
                ? []
                : [.product(name: "DatadogCore", package: "dd-sdk-ios")]
            )
        )
    ]
)

for target in package.targets {
    target.swiftSettings = (target.swiftSettings ?? []) + [
        .enableUpcomingFeature("ExistentialAny"),
        .enableUpcomingFeature("GlobalConcurrency"),
        .enableExperimentalFeature("StrictConcurrency")
    ]
}
