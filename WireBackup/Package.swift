// swift-tools-version: 6.0

import PackageDescription

let package = Package(
    name: "WireBackup",
    platforms: [.iOS("16.4"), .macOS(.v12)],
    products: [
        .library(name: "WireBackup", targets: ["WireBackup"])
    ],
    dependencies: [
        .package(url: "https://github.com/swiftlang/swift-docc-plugin", from: "1.1.0"),
        .package(path: "../WireFoundation"),
        .package(path: "../WireLogging"),
        .package(path: "../WirePlugins")
    ],
    targets: [
        .target(
            name: "WireBackup",
            dependencies: [
                "KaliumBackup",
                "WireFoundation",
                "WireLogging"
            ]
        ),
        .target(
            name: "WireBackupSupport",
            dependencies: [
                "WireBackup"
            ],
            plugins: [.plugin(name: "SourceryPlugin", package: "WirePlugins")]
        ),
        .testTarget(
            name: "WireBackupTests",
            dependencies: [
                "WireBackup",
                "WireBackupSupport",
                .product(name: "WireFoundationSupport", package: "WireFoundation")
            ]
        ),
        .binaryTarget(
            name: "KaliumBackup",
            url: "https://github.com/wireapp/kalium/releases/download/backup%2F0.0.1/KaliumBackup.xcframework.zip",
            checksum: "03e6e6398f65e0366a772b0b3ec710bd74d9e0482739781f649bcbd89be482ac"
        )
    ],
    swiftLanguageModes: [.v6]
)

for target in package.targets where target.type != .binary {
    target.swiftSettings = (target.swiftSettings ?? []) + [
        .enableUpcomingFeature("InternalImportsByDefault"),
        .enableUpcomingFeature("ExistentialAny")
    ]
}
