// swift-tools-version: 5.10

import PackageDescription

let package = Package(
    name: "WireAPI",
    platforms: [
        .iOS(.v15),
        .macOS(.v12)
    ],
    products: [
        .library(
            name: "WireAPI",
            targets: ["WireAPI"]
        ),
        .library(
            name: "WireAPISupport",
            targets: ["WireAPISupport"]
        )
    ],
    dependencies: [
        .package(
            url: "https://github.com/apple/swift-docc-plugin",
            from: "1.1.0"
        ),
        .package(
            url: "https://github.com/pointfreeco/swift-snapshot-testing",
            from: "1.16.0"
        ),
        .package(path: "../SourceryPlugin")
    ],
    targets: [
        .target(
            name: "WireAPI"
        ),
        .target(
            name: "WireAPISupport",
            dependencies: ["WireAPI"],
            plugins: [
                .plugin(
                    name: "SourceryPlugin",
                    package: "SourceryPlugin"
                )
            ]
        ),
        .testTarget(
            name: "WireAPITests",
            dependencies: [
                "WireAPI",
                .product(
                    name: "SnapshotTesting",
                    package: "swift-snapshot-testing"
                )
            ],
            resources: [
                .process("Resources")
            ]
        )
    ]
)
