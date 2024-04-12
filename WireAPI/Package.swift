// swift-tools-version: 5.10

import PackageDescription

let package = Package(
    name: "WireAPI",
    platforms: [
        .iOS(.v15)
    ],
    products: [
        .library(
            name: "WireAPI",
            targets: ["WireAPI"]
        ),
    ],
    targets: [
        .target(
            name: "WireAPI"
        ),
        .testTarget(
            name: "WireAPITests",
            dependencies: ["WireAPI"]
        )
    ]
)
