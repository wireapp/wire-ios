// swift-tools-version: 5.10

import PackageDescription

let package = Package(
    name: "WireNetworkSupport",
    platforms: [.iOS(.v17), .macOS(.v12)],
    products: [
        .library(name: "WireNetworkSupport", type: .dynamic, targets: ["WireNetworkSupport"])
    ],
    dependencies: [
        .package(path: "../WireNetwork"),
        .package(path: "../WirePlugins")
    ],
    targets: [
        .target(
            name: "WireNetworkSupport",
            dependencies: ["WireNetwork"],
            plugins: [
                .plugin(name: "SourceryPlugin", package: "WirePlugins")
            ]
        )
    ]
)
