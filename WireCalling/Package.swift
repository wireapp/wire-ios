// swift-tools-version: 6.2

import Foundation
import PackageDescription

let WireTestingPackage = Target.Dependency.product(name: "WireTestingPackage", package: "WireFoundation")

let package = Package(
    name: "WireCalling",
    defaultLocalization: "en",
    platforms: [.iOS(.v17), .macOS(.v12)],
    products: [
        .library(name: "WireCallingDomain", targets: ["WireCallingDomain"]),
        .library(name: "WireCallingDomainSupport", targets: ["WireCallingDomainSupport"]),
        .library(name: "WireCallingData", targets: ["WireCallingData"]),
        .library(name: "WireCallingAssembly", targets: ["WireCallingAssembly"]),
        .library(name: "WireCallingUI", targets: ["WireCallingUI"])
    ],
    dependencies: [
        .package(path: "../WireData"),
        .package(path: "../WireFoundation"),
        .package(path: "../WireMockable"),
        .package(path: "../WireNetwork"),
        .package(path: "../WirePlugins"),
        .package(path: "../WireLogging"),
        .package(name: "WireUI", path: "../WireUI")
    ],
    targets: [
        .target(
            name: "WireCallingDomain",
            dependencies: [
                "WireFoundation",
                "WireLogging",
                "WireMockable"
            ]
        ),
        .target(
            name: "WireCallingDomainSupport",
            dependencies: [
                "WireCallingDomain",
                "WireCallingData"
            ],
            plugins: [.plugin(name: "SourceryPlugin", package: "WirePlugins")]
        ),
        .target(
            name: "WireCallingData",
            dependencies: [
                "WireCallingDomain",
                "WireData",
                "WireLogging",
                "WireNetwork",
                "WireMockable"
            ]
        ),
        .target(
            name: "WireCallingAssembly",
            dependencies: [
                "WireCallingDomain",
                "WireCallingUI",
                "WireCallingData"
            ]
        ),
        .target(
            name: "WireCallingUI",
            dependencies: [
                "WireCallingDomain",
                "WireCallingDomainSupport",
                .product(name: "WireDesign", package: "WireUI"),
                "WireFoundation",
                "WireLogging"
            ],
            plugins: [.plugin(name: "SwiftGenPlugin", package: "WirePlugins")]
        ),
        .testTarget(
            name: "WireCallingTests",
            dependencies: [
                "WireCallingAssembly",
                "WireCallingUI",
                "WireCallingDomain",
                "WireCallingDomainSupport",
                "WireCallingData",
                .product(name: "WireDesign", package: "WireUI"),
                .product(name: "WireFoundationSupport", package: "WireFoundation"),
                .product(name: "WireNetworkSupport", package: "WireNetwork")
            ],
        ),
    ]
)

for target in package.targets {
    if target.isTest {
        target.dependencies += [WireTestingPackage]
    }
}

// open --env CI wire-ios-mono.xcworkspace
// or
// CI= swift build
let isCI = ProcessInfo.processInfo.environment["CI"] != nil

for target in package.targets where target.type != .binary {
    target.swiftSettings = (target.swiftSettings ?? []) + [
        .enableUpcomingFeature("ExistentialAny"),
        .enableUpcomingFeature("InternalImportsByDefault"),
        .enableUpcomingFeature("MemberImportVisibility"),
        .enableUpcomingFeature("StrictMemorySafety"),
        isCI ? .unsafeFlags(["-warnings-as-errors"]) : nil
    ].compactMap(\.self)
}
