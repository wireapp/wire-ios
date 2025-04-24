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
                "WireAPI",
                "WireBackup",
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
            name: "WireBackup",
            url: "https://media.githubusercontent.com/media/wireapp/wire-ios/16aeff5783fbd8d66d914bd6a8de3d60d2b3c7f5/WireDomain/Frameworks/WireBackup.xcframework.zip?download=true",
            checksum: "ac0896ea966ffdf9199ed99410345db11e82ef76b9ee5f87a237ebc5c1fca9df"
        )
        // .binaryTarget(
        //     name: "WireBackup",
        //     path: "../../wire-android/kalium/backup/build/XCFrameworks/release/WireBackup.xcframework"
        // )
    ]
)

for target in package.targets where target.type != .binary {
    target.swiftSettings = [
        .enableUpcomingFeature("InternalImportsByDefault"),
        .enableUpcomingFeature("ExistentialAny")
    ]
}
