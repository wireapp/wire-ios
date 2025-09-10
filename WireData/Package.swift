// swift-tools-version: 6.1
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "WireData",
    products: [
        .library(
            name: "WireData",
            type: .dynamic,
            targets: ["WireData"]
        ),
    ],
    targets: [
        .target(
            name: "WireData"
        ),
        .testTarget(
            name: "WireDataTests",
            dependencies: ["WireData"]
        ),
    ]
)
