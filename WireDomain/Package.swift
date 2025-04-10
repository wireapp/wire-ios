// swift-tools-version: 6.0
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "WireDomainPackage",
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
                .product(name: "WireFoundation", package: "WireFoundation"),
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
            url: "https://media.githubusercontent.com/media/wireapp/wire-ios/949125cecbac0c0e59bda9d33162786240d21bb2/WireDomain/Frameworks/WireBackup.xcframework.zip?download=true",
            checksum: "1d90f0689e49b4637808f013526597671534d0b7c2e62818d26dd2d1004d9012"
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
