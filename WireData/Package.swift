// swift-tools-version: 6.1

import PackageDescription

let package = Package(
    name: "WireData",
    products: [
        .library(
            name: "WireData",
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
