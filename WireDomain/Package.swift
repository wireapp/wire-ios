// swift-tools-version: 6.0
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "WireDomainPackage",
    defaultLocalization: "en",
    platforms: [.iOS("16.4"), .macOS(.v12)],
    products: [
        .library(name: "WireDomainPackage", targets: ["WireDomainPackage"]),
        .library(name: "WireDomainPackageSupport", targets: ["WireDomainPackageSupport"])
    ],
    dependencies: [
        .package(url: "https://github.com/swiftlang/swift-docc-plugin", from: "1.1.0"),
        .package(path: "../WireAPI"),
        .package(path: "../WireFoundation"),
        .package(path: "../WireLogging"),
        .package(path: "../WirePlugins"),
        .package(url: "https://github.com/rickclephas/KMP-NativeCoroutines.git", exact: "1.0.0-ALPHA-27")
    ],
    targets: [
        .target(
            name: "WireDomainPackage",
            dependencies: [
                "KaliumBackup",
                "WireAPI",
                "WireLogging",
                "WireFoundation",
                .product(name: "KMPNativeCoroutinesAsync", package: "KMP-NativeCoroutines")
            ]
        ),
        .target(
            name: "WireDomainPackageSupport",
            dependencies: ["WireDomainPackage"],
            plugins: [.plugin(name: "SourceryPlugin", package: "WirePlugins")]
        ),
        .testTarget(
            name: "WireDomainPackageTests",
            dependencies: [
                "WireDomainPackage",
                "WireDomainPackageSupport",
                .product(name: "WireFoundationSupport", package: "WireFoundation")
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
    ]
)

for target in package.targets where target.type != .binary {
    target.swiftSettings = [
        .enableUpcomingFeature("InternalImportsByDefault"),
        .enableUpcomingFeature("ExistentialAny")
    ]
}
