// swift-tools-version: 6.0
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "WireCells",
    platforms: [.iOS(.v16), .macOS(.v12)],
    products: [
        // Products define the executables and libraries a package produces, making them visible to other packages.
        .library(
            name: "WireCellsAPI",
            targets: ["API"]
        ),
        .library(
            name: "WireCellsBindings",
            targets: ["Bindings"]
        ),
    ],
    dependencies: [
        .package(url: "https://github.com/pydio/cells-sdk-swift.git", branch: "v5-dev"),
        .package(url: "https://github.com/awslabs/aws-sdk-swift.git", from: "1.0.0")
    ],
    targets: [
        // Targets are the basic building blocks of a package, defining a module or a test suite.
        // Targets can depend on other targets in this package and products from dependencies.
        .target(
            name: "API",
            dependencies: [
                .product(name: "CellsSDK", package: "cells-sdk-swift")
            ]
        ),
        .target(name: "Bindings"),
        .target(
            name: "Implementation",
            dependencies: [
                "API",
                .product(name: "AWSS3", package: "aws-sdk-swift"),
                .product(name: "CellsSDK", package: "cells-sdk-swift")
            ]
        ),
        .testTarget(
            name: "WireCellsTests",
            dependencies: [
                "API",
                "Implementation"
            ]
        ),
    ]
)
