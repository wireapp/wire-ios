// swift-tools-version: 5.10

import PackageDescription

let package = Package(
    name: "SourceryPlugin",
    platforms: [
        .iOS(.v15)
    ],
    products: [
        .plugin(name: "SourceryPlugin", targets: ["SourceryPlugin"])
    ],
    dependencies: [],
    targets: [
        .binaryTarget(
            name: "sourcery3",
            url: "https://github.com/krzysztofzablocki/Sourcery/releases/download/2.1.7/sourcery-2.1.7.artifactbundle.zip",
            checksum: "b54ff217c78cada3f70d3c11301da03a199bec87426615b8144fc9abd13ac93b"
        ),
        .plugin(
            name: "SourceryPlugin",
            capability: .buildTool(),
            dependencies: ["sourcery3"]
        )
    ]
)
