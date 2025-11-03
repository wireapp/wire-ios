// swift-tools-version: 6.2

import Foundation
import PackageDescription

let package = Package(
    name: "WireLegacyLogging",
    platforms: [.iOS("16.4"), .macOS(.v12)],
    products: [
        .library(name: "WireLegacyLogging", targets: ["WireLegacyLogging"]),
        .library(name: "WireLegacyLoggingSupport", targets: ["WireLegacyLoggingSupport"])
    ],
    dependencies: [
        .package(path: "../WirePlugins")
    ],
    targets: [
        .target(name: "WireLegacyLogging"),
        .target(
            name: "WireLegacyLoggingSupport",
            dependencies: ["WireLegacyLogging"],
            plugins: [.plugin(name: "SourceryPlugin", package: "WirePlugins")]
        ),
        .testTarget(
            name: "WireLegacyLoggingTests",
            dependencies: ["WireLegacyLogging"]
        )
    ]
)

// open --env CI wire-ios-mono.xcworkspace
// or
// CI= swift build
let isCI = ProcessInfo.processInfo.environment["CI"] != nil

for target in package.targets {
    target.swiftSettings = (target.swiftSettings ?? []) + [
        .enableUpcomingFeature("ExistentialAny"),
        .enableUpcomingFeature("InternalImportsByDefault"),
        .enableUpcomingFeature("MemberImportVisibility"),
        .enableUpcomingFeature("StrictMemorySafety"),
        isCI ? .unsafeFlags(["-warnings-as-errors"]) : nil
    ].compactMap(\.self)
}
