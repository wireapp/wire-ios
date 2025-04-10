// swift-tools-version: 6.0
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "WirePlugins",
    products: [
        .plugin(name: "SourceryPlugin", targets: ["SourceryPlugin"]),
        .plugin(name: "SwiftGenPlugin", targets: ["SwiftGenPlugin"])
    ],
    targets: [
        .binaryTarget(
            name: "sourcery",
            url: "https://github.com/krzysztofzablocki/Sourcery/releases/download/2.2.6/sourcery-2.2.6.artifactbundle.zip",
            checksum: "00ddb01d968cf5a1b9971a997f362553b2cf57ccdd437e7ecde9c7891ee9e4c1"
        ),

        .plugin(
            name: "SourceryPlugin",
            capability: .buildTool(),
            dependencies: ["sourcery"],
            exclude: ["./Stencils/LegacyAutoMockable.stencil"]
        ),

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
