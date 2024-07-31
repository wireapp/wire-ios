// swift-tools-version: 5.10

import PackageDescription

let package = Package(
    name: "SourceryPlugin",
    platforms: [.iOS(.v15), .macOS(.v12)],
    products: [
        .plugin(name: "SourceryPlugin", targets: ["SourceryPlugin"])
    ],
    dependencies: [],
    targets: [
        .binaryTarget(
            name: "sourcery",
            url: "https://github.com/krzysztofzablocki/Sourcery/releases/download/2.2.4/sourcery-2.2.4.artifactbundle.zip",
            checksum: "79282fd22949653dcaf0ab6a215d33a913ce09840f577c5959b7e94292b12bd4"
        ),
        .plugin(
            name: "SourceryPlugin",
            capability: .buildTool(),
            dependencies: ["sourcery"]
        )
    ]
)
