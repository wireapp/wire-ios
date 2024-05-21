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
        )
    ],
    targets: [
        .target(
            name: "WireAPI"
        ),
        .target(
            name: "WireAPISupport",
            dependencies: [
                "WireAPI"
            ],
            plugins: [
                .plugin(name: "WireAPIPlugin")
            ]
        ),
        .binaryTarget(
            name: "sourcery2",
            url: "https://github.com/krzysztofzablocki/Sourcery/releases/download/2.1.7/sourcery-2.1.7.artifactbundle.zip",
            checksum: "b54ff217c78cada3f70d3c11301da03a199bec87426615b8144fc9abd13ac93b"
        ),
        .plugin(
            name: "WireAPIPlugin",
            capability: .buildTool(),
            dependencies: ["sourcery2"]
        ),
        .testTarget(
            name: "WireAPITests",
            dependencies: [
                "WireAPI",
                "WireAPISupport",
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
