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
    targets: [
        .target(
            name: "WireAnalytics",
            dependencies: resolveWireAnalyticsDependencies()
        ),
        .target(
            name: "WireDatadog",
            dependencies: [
                .target(name: "Datadog")
//                .product(name: "DatadogCore", package: "Datadog"),
//                .product(name: "DatadogCrashReporting", package: "dd-sdk-ios"),
//                .product(name: "DatadogLogs", package: "dd-sdk-ios"),
//                .product(name: "DatadogRUM", package: "dd-sdk-ios"),
//                .product(name: "DatadogTrace", package: "dd-sdk-ios")
            ]
        ),
        .binaryTarget(
            name: "Datadog",
            url: "https://github.com/DataDog/dd-sdk-ios/releases/download/2.18.0/Datadog.xcframework.zip",
            checksum: "f912efbb162e822f830dd5f82de15b444af564b4df2c23cf3a08621c63252e0b"
        )
     
//            .target(name: "DatadogCore", dependencies: ["Datadog"], packageAccess: <#T##Bool#>),
//        .target(name: "DatadogCrashReporting", dependencies: ["Datadog"]),
//        .target(name: "DatadogLogs", dependencies: ["Datadog"]),
//        .target(name: "DatadogRUM", dependencies: ["Datadog"]),
//        .target(name: "DatadogTrace", dependencies: ["Datadog"])
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

let swiftSettings: [SwiftSetting] = [
    .enableUpcomingFeature("ExistentialAny"),
    .enableUpcomingFeature("GlobalConcurrency"),
    .enableExperimentalFeature("StrictConcurrency")
]
