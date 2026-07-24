// swift-tools-version: 6.2

import PackageDescription

let package = Package(
    name: "WirePlugins",
    products: [
        .plugin(name: "RunMockolo", targets: ["RunMockolo"]),
        .plugin(name: "SourceryPlugin", targets: ["SourceryPlugin"]),
        .plugin(name: "SwiftGenPlugin", targets: ["SwiftGenPlugin"])
    ],
    targets: [
        .binaryTarget(
            name: "mockolo",
            url: "https://github.com/uber/mockolo/releases/download/2.6.1/mockolo.artifactbundle.zip",
            checksum: "8ed3fd73a7b76b87b3d53cd702e5b977443d4ffd00d50161200e2526fc08e7bf"
        ),
        .plugin(
            name: "RunMockolo",
            capability: .buildTool(),
            dependencies: [.target(name: "mockolo")]
        ),
        .binaryTarget(
            name: "sourcery",
            url: "https://github.com/krzysztofzablocki/Sourcery/releases/download/2.3.0/sourcery-2.3.0.artifactbundle.zip",
            checksum: "2fb2ae820c4d12f77232bacba5ee719fff9d61c71c3e8c6067691b2e90aa4ba7"
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
