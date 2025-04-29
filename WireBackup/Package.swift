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
            url: "https://media.githubusercontent.com/media/wireapp/wire-ios/133dbdd065eb515e5fe32803380dae8a864729f2/WireBackup/Frameworks/KaliumBackup.xcframework.zip?download=true",
            checksum: "dcd518218c20a27cd99b30380be722b4bdbc2ca77b2527cb45cd6172dad0c973"
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
