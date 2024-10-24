// swift-tools-version: 5.10

import PackageDescription

let package = Package(
    name: "SourceryPlugin",
    platforms: [.iOS(.v16), .macOS(.v12)],
    products: [
        .plugin(name: "SourceryPlugin", targets: ["SourceryPlugin"])
    ],
    dependencies: [],
    targets: [
        .binaryTarget(
            name: "sourcery",
            url: "https://github.com/krzysztofzablocki/Sourcery/releases/download/2.2.5/sourcery-2.2.5.artifactbundle.zip",
            checksum: "875ef49ba5e5aeb6dc6fb3094485ee54062deb4e487827f5756a9ea75b66ffd8"
        ),
        .plugin(
            name: "SourceryPlugin",
            capability: .buildTool(),
            dependencies: ["sourcery"]
        )
    ]
)
