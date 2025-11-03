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
        .package(url: "https://github.com/weichsel/ZIPFoundation.git", .upToNextMajor(from: "0.9.0")),
        .package(path: "../WireFoundation"),
        .package(path: "../WireLegacyLogging"),
        .package(path: "../WirePlugins")
    ],
    targets: [
        .target(
            name: "WireBackup",
            dependencies: [
                "KaliumBackup",
                "WireFoundation",
                "WireLegacyLogging",
                .product(name: "WireUtilitiesPackage", package: "WireFoundation")
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
                "KaliumBackup",
                "WireBackup",
                "WireBackupSupport",
                .product(name: "WireFoundationSupport", package: "WireFoundation"),
                "ZIPFoundation"
            ],
            resources: [
                .copy("Resources/android-encrypted.wbu"),
                .copy("Resources/android-unencrypted.wbu"),
                .copy("Resources/ios-encrypted.wbu"),
                .copy("Resources/ios-unencrypted.wbu"),
                .copy("Resources/web-encrypted.wbu"),
                .copy("Resources/web-unencrypted.wbu")
            ]
        ),
        .binaryTarget(
            name: "KaliumBackup",
            url: "https://github.com/wireapp/kalium/releases/download/backup%2F0.0.3/KaliumBackup.xcframework.zip",
            checksum: "2f78301880c372b058479bf432b751f5cee82a362e73da4737436be292bdb0ff"
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
