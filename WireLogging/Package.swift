// swift-tools-version: 6.2

import Foundation
import PackageDescription

let package = Package(
    name: "WireLogging",
    platforms: [.iOS("16.4"), .macOS(.v12)],
    products: [
        .library(name: "WireLogging", targets: ["WireLogging"]),
        .library(name: "WireLoggingSupport", targets: ["WireLoggingSupport"]),
        .library(name: "WireLegacyLogging", targets: ["WireLegacyLogging"]),
        .library(name: "WireLegacyLoggingSupport", targets: ["WireLegacyLoggingSupport"])
    ],
    dependencies: [
        .package(url: "https://github.com/krzysztofzablocki/Sourcery.git", from: "2.0.0"),
        .package(url: "https://github.com/swiftlang/swift-docc-plugin", from: "1.1.0"),
        .package(path: "../WirePlugins")
    ],
    targets: [
        .target(name: "WireLogging"),
        .target(
            name: "WireLoggingSupport",
            dependencies: ["WireLogging"],
            plugins: [
                // .plugin(name: "SourceryPlugin", package: "WirePlugins")
                .plugin(name: "SourceryCommandPlugin", package: "Sourcery")
            ]
        ),
        .testTarget(
            name: "WireLoggingTests",
            dependencies: ["WireLogging", "WireLoggingSupport"]
        ),

        .target(
            name: "WireLegacyLogging",
            dependencies: [
                "WireLogging"
            ]
        ),
        .target(
            name: "WireLegacyLoggingSupport",
            dependencies: ["WireLegacyLogging"],
            plugins: [
                .plugin(name: "SourceryPlugin", package: "WirePlugins")
            ]
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
