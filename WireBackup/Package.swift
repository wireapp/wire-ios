// swift-tools-version: 6.0

import PackageDescription

let package = Package(
    name: "WireBackup",
    platforms: [.iOS("16.4"), .macOS(.v12)],
    products: [
        .library(name: "WireBackup", targets: ["WireBackup"])
    ],
    dependencies: [
        .package(url: "https://github.com/rickclephas/KMP-NativeCoroutines.git", exact: "1.0.0-ALPHA-27"),
        .package(url: "https://github.com/swiftlang/swift-docc-plugin", from: "1.1.0"),
        .package(path: "../WireFoundation"),
        .package(path: "../WirePlugins")
    ],
    targets: [
        .target(
            name: "WireBackup",
            dependencies: [
                "KaliumBackup",
                .product(name: "KMPNativeCoroutinesAsync", package: "KMP-NativeCoroutines"),
                "WireFoundation"
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
                "WireBackupSupport"
            ]
        ),

        .binaryTarget(
            name: "KaliumBackup",
            url: "https://media.githubusercontent.com/media/wireapp/wire-ios/ef4ecddb36eb5fe9c743b4fe48f224d8ef846532/WireDomain/Frameworks/KaliumBackup.xcframework.zip?download=true",
            checksum: "e6165410781ef8207a8d5bdc02bd04f092517da37e9e5bb57879610685c31806"
        )
        // .binaryTarget(
        //     name: "KaliumBackup",
        //     path: "../../wire-android/kalium/backup/build/XCFrameworks/release/KaliumBackup.xcframework"
        // )
    ],
    swiftLanguageModes: [.v6]
)

for target in package.targets where target.type != .binary {
    target.swiftSettings = (target.swiftSettings ?? []) + [
        .enableUpcomingFeature("InternalImportsByDefault"),
        .enableUpcomingFeature("ExistentialAny")
    ]
}
