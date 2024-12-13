// swift-tools-version: 6.0

import PackageDescription

let package = Package(
    name: "WireDeveloperTools",
    products: [
        .library(name: "WireDeveloperTools", targets: ["WireDeveloperTools"]),
    ],
    targets: [
        .target(name: "WireDeveloperTools"),
        .testTarget(
            name: "WireDeveloperToolsTests",
            dependencies: ["WireDeveloperTools"]
        ),
    ]
)
