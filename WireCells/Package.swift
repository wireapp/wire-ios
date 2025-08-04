// swift-tools-version: 6.0
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let WireTestingPackage = Target.Dependency.product(name: "WireTestingPackage", package: "WireFoundation")

let package = Package(
    name: "WireCells",
    defaultLocalization: "en",
    platforms: [.iOS("16.4"), .macOS(.v12)],
    products: [
        // Products define the executables and libraries a package produces, making them visible to other packages.
        .library(
            name: "WireCellsAPI",
            targets: ["WireCellsAPI"]
        ),
        .library(
            name: "WireCellsBindings",
            targets: ["WireCellsBindings"]
        ),
        .library(
            name: "WireCellsUI",
            targets: ["WireCellsUI"]
        ),
    ],
    dependencies: [
        .package(url: "https://github.com/pydio/cells-sdk-swift.git", from: "0.1.1-alpha10"),
        .package(url: "https://github.com/awslabs/aws-sdk-swift.git", from: "1.0.0"),
        .package(url: "https://github.com/apple/swift-collections.git", from: "1.1.4"),
        .package(name: "WireFoundation", path: "../WireFoundation"),
        .package(name: "WireUI", path: "../WireUI"),
        .package(path: "../WirePlugins"),
        .package(path: "../WireLogging")
    ],
    targets: [
        // Targets are the basic building blocks of a package, defining a module or a test suite.
        // Targets can depend on other targets in this package and products from dependencies.
        .target(
            name: "WireCellsAPI",
            dependencies: [
                .product(name: "CellsSDK", package: "cells-sdk-swift")
            ]
        ),
        .target(
            name: "WireCellsBindings",
            dependencies: [
                "WireCellsAPI",
                "WireCellsImplementation"
            ]
        ),
        .target(
            name: "WireCellsImplementation",
            dependencies: [
                "WireCellsAPI",
                "WireLogging",
                .product(name: "AWSS3", package: "aws-sdk-swift"),
                .product(name: "CellsSDK", package: "cells-sdk-swift"),
                .product(name: "Collections", package: "swift-collections")
            ]
        ),
        .target(
            name: "WireCellsUI",
            dependencies: [
                "WireCellsAPI",
                "WireFoundation",
                .product(name: "WireDesign", package: "WireUI"),
                .product(name: "WireReusableUIComponents", package: "WireUI")
            ],
            plugins: [.plugin(name: "SwiftGenPlugin", package: "WirePlugins")]
        ),
        .testTarget(
            name: "WireCellsImplementationTests",
            dependencies: [
                "WireCellsImplementation",
                "WireCellsImplementationSupport"
            ]
        ),
        .testTarget(
            name: "WireCellsUITests",
            dependencies: [
                "WireCellsUI"
            ]
        ),
        .target(
            name: "WireCellsImplementationSupport",
            dependencies: ["WireCellsImplementation"],
            plugins: [.plugin(name: "SourceryPlugin", package: "WirePlugins")]
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
