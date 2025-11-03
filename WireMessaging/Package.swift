// swift-tools-version: 6.0

import PackageDescription

let WireTestingPackage = Target.Dependency.product(name: "WireTestingPackage", package: "WireFoundation")

let package = Package(
    name: "WireMessaging",
    defaultLocalization: "en",
    platforms: [.iOS("16.4"), .macOS(.v12)],
    products: [
        .library(name: "WireMessagingDomain", targets: ["WireMessagingDomain"]),
        .library(name: "WireMessagingAssembly", targets: ["WireMessagingAssembly"]),
        .library(name: "WireMessagingUI", targets: ["WireMessagingUI"])
    ],
    dependencies: [
        .package(url: "https://github.com/pydio/cells-sdk-swift.git", from: "0.1.1-alpha15"),
        .package(url: "https://github.com/awslabs/aws-sdk-swift.git", from: "1.0.0"),
        .package(url: "https://github.com/apple/swift-collections.git", from: "1.1.4"),
        .package(name: "WireFoundation", path: "../WireFoundation"),
        .package(path: "../WirePlugins"),
        .package(path: "../WireLegacyLogging"),
        .package(name: "WireUI", path: "../WireUI"),
        .package(path: "../WireData")
    ],
    targets: [
        .target(
            name: "WireMessagingDomain",
            dependencies: [
                .product(name: "CellsSDK", package: "cells-sdk-swift"),
                "WireFoundation",
                "WireLegacyLogging"
            ]
        ),
        .target(
            name: "WireMessagingData",
            dependencies: [
                "WireData",
                "WireMessagingDomain",
                "WireLegacyLogging",
                .product(name: "AWSS3", package: "aws-sdk-swift"),
                .product(name: "CellsSDK", package: "cells-sdk-swift"),
                .product(name: "Collections", package: "swift-collections")
            ]
        ),
        .target(
            name: "WireMessagingAssembly",
            dependencies: [
                "WireMessagingDomain",
                "WireMessagingUI",
                "WireMessagingData"
            ]
        ),
        .target(
            name: "WireMessagingUI",
            dependencies: [
                "WireMessagingDomain",
                "WireMessagingDomainSupport",
                .product(name: "WireDesign", package: "WireUI"),
                .product(name: "WireReusableUIComponents", package: "WireUI"),
                .product(name: "WireAccountImageUI", package: "WireUI"),
                "WireFoundation"
            ],
            plugins: [.plugin(name: "SwiftGenPlugin", package: "WirePlugins")]
        ),
        .target(
            name: "WireMessagingDomainSupport",
            dependencies: [
                "WireMessagingDomain",
                "WireMessagingData"
            ],
            plugins: [.plugin(name: "SourceryPlugin", package: "WirePlugins")]
        ),
        .testTarget(
            name: "WireMessagingTests",
            dependencies: [
                "WireMessagingData",
                "WireMessagingUI",
                "WireMessagingDomainSupport",
                .product(name: "WireDesign", package: "WireUI"),
                "WireFoundation"
            ],
            resources: [
                .process("Resources/TestFiles/")
            ]
        ),
    ]
)

for target in package.targets {
    if target.isTest {
        target.dependencies += [WireTestingPackage]
    }
}

for target in package.targets {
    target.swiftSettings = (target.swiftSettings ?? []) + [
        .enableUpcomingFeature("InternalImportsByDefault"),
        .enableUpcomingFeature("ExistentialAny")
    ]
}
