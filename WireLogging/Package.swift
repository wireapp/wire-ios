// swift-tools-version: 6.2

import Foundation
import PackageDescription

let package = Package(
    name: "WireLogging",
    platforms: [.iOS("16.4"), .macOS(.v12)],
    products: [
        .library(name: "WireLogging", targets: ["WireLogging"]),
        .library(name: "WireLoggingSupport", targets: ["WireLoggingSupport"])
    ],
    dependencies: [
        .package(path: "../WirePlugins")
    ],
    targets: [
        .target(name: "WireLogging"),
        .target(
            name: "WireLoggingSupport",
            dependencies: ["WireLogging"],
            plugins: [.plugin(name: "SourceryPlugin", package: "WirePlugins")]
        ),
        .testTarget(
            name: "WireLoggingTests",
            dependencies: ["WireLogging"]
        )
    ]
)

for target in package.targets {
    target.swiftSettings = (target.swiftSettings ?? []) + [
        .enableUpcomingFeature("ExistentialAny"),
        .enableUpcomingFeature("InternalImportsByDefault"),
        .enableUpcomingFeature("MemberImportVisibility"),
        .enableUpcomingFeature("StrictMemorySafety"),
        isCI ? .unsafeFlags(["-warnings-as-errors"]) : nil
    ].compactMap(\.self)
}

let isCI = ProcessInfo.processInfo.environment["CI"] != nil
