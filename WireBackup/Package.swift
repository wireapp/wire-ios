// swift-tools-version: 6.0

import PackageDescription

let package = Package(
    name: "WireBackup",
    platforms: [.iOS("16.4"), .macOS(.v13)],
    products: [
        .library(name: "WireBackup", targets: ["WireBackup"])
    ],
    dependencies: [
        .package(url: "https://github.com/swiftlang/swift-docc-plugin", from: "1.1.0"),
        .package(url: "https://github.com/weichsel/ZIPFoundation.git", from: "0.9.19"),
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
        .executableTarget(
            name: "WireBackupCLI",
            dependencies: ["KaliumBackup", "WireBackup", "ZIPFoundation"]
        ),

        .binaryTarget(
            name: "KaliumBackup",
            url: "https://media.githubusercontent.com/media/wireapp/wire-ios/60fa91813b0b36bde4769b63982c2f5511c15a94/WireBackup/Frameworks/KaliumBackup.xcframework.zip?download=true",
            checksum: "2ea1f7516165a0928809ea2d80f94de2949eb686c0ca3ddccf1908a01d63573b"
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
