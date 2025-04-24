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
        .package(path: "../WirePlugins")
    ],
    targets: [
        .target(
            name: "WireBackup"
        ),
        .testTarget(
            name: "WireBackupTests",
            dependencies: ["WireBackup"]
        ),
        .target(
            name: "WireBackupSupport",
            dependencies: ["WireBackup"],
            plugins: [.plugin(name: "SourceryPlugin", package: "WirePlugins")]
        )
    ],
    swiftLanguageModes: [.v6]
)

for target in package.targets where target.name != "Clibsodium" {
    target.swiftSettings = (target.swiftSettings ?? []) + [
        .enableUpcomingFeature("InternalImportsByDefault"),
        .enableUpcomingFeature("ExistentialAny")
    ]
}
