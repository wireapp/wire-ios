// swift-tools-version: 6.0
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "WirePlugins",
    products: [
        .plugin(
            name: "SwiftGenPlugin",
            targets: ["SwiftGenPlugin"]),
    ],
    targets: [
        .plugin(
            name: "SwiftGenPlugin",
            capability: .buildTool(),
            dependencies: ["swiftgen"]
        ),
        .binaryTarget(
            name: "swiftgen",
            url: "https://github.com/SwiftGen/SwiftGen/releases/download/6.6.3/swiftgen-6.6.3.artifactbundle.zip",
            checksum: "caf1feaf93dd32bc5037f0b6ded8d0f4fe28ab5d2f6e5c3edf2572006ba0b7eb"
        )
    ]
)
