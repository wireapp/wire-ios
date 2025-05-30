// swift-tools-version: 6.1

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
            url: "https://github.com/krzysztofzablocki/Sourcery/releases/download/2.2.7/sourcery-2.2.7.artifactbundle.zip",
            checksum: "33f4590a657cc3d6631d81cd557b9ac47594e709623f3e61baa254334e950da6"
        ),

        .plugin(
            name: "SourceryPlugin",
            capability: .buildTool(),
            dependencies: ["sourcery"],
            exclude: [
                "./Stencils/AutoMockable.stencil",
                "./Stencils/LegacyAutoMockable.stencil"
            ]
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
