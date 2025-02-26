// swift-tools-version: 6.0
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let WireTestingPackage = Target.Dependency.product(name: "WireTestingPackage", package: "WireFoundation")

let package = Package(
    name: "WireCells",
    platforms: [.iOS(.v16), .macOS(.v12)],
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
        .package(url: "https://github.com/pydio/cells-sdk-swift.git", branch: "v0.1.1-alpha02"),
        .package(url: "https://github.com/awslabs/aws-sdk-swift.git", from: "1.0.0"),
        .package(name: "WireFoundation", path: "../WireFoundation"),
        .package(name: "WireUI", path: "../WireUI")
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
        .target(name: "WireCellsBindings"),
        .target(
            name: "WireCellsImplementation",
            dependencies: [
                "WireCellsAPI",
                .product(name: "AWSS3", package: "aws-sdk-swift"),
                .product(name: "CellsSDK", package: "cells-sdk-swift")
            ]
        ),
        .target(
            name: "WireCellsUI",
            dependencies: [
                .product(name: "WireDesign", package: "WireUI")
            ]
        ),
        .testTarget(
            name: "WireCellsTests",
            dependencies: [
                "WireCellsAPI",
                "WireCellsImplementation"
            ]
        ),
        .testTarget(
            name: "WireCellsUITests",
            dependencies: [
                "WireCellsUI"
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
        .enableUpcomingFeature("FullTypedThrows"),
        .enableUpcomingFeature("ExistentialAny")
    ]
}
