// swift-tools-version: 6.0
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "WireDomainPackage",
    platforms: [.iOS(.v16), .macOS(.v12)],
    products: [
        .library(name: "WireDomainPackage", targets: ["WireDomainPkg"]),
        .library(name: "WireDomainPackageSupport", targets: ["WireDomainPkgSupport"])
    ],
    dependencies: [
        .package(url: "https://github.com/swiftlang/swift-docc-plugin", from: "1.1.0"),
        .package(path: "../WireAPI"),
        .package(path: "../WireFoundation"),
        .package(path: "../WireLogging"),
        .package(path: "../WirePlugins")
    ],
    targets: [
        .target(
            name: "WireDomainPkg",
            dependencies: [
                "WireAPI",
                "WireBackup",
                "WireLogging",
                .product(name: "WireFoundation", package: "WireFoundation")
            ]
        ),
        .target(
            name: "WireDomainPkgSupport",
            dependencies: ["WireDomainPkg"],
            plugins: [.plugin(name: "SourceryPlugin", package: "WirePlugins")]
        ),
        .testTarget(
            name: "WireDomainPkgTests",
            dependencies: [
                "WireDomainPkg",
                "WireDomainPkgSupport",
                .product(name: "WireFoundationSupport", package: "WireFoundation")
            ]
        ),

        .binaryTarget(
            name: "WireBackup",
            url: "https://media.githubusercontent.com/media/wireapp/wire-ios/eaba540acd2fdb25ec07cc4254c69fb7cce8ffde/WireDomain/Frameworks/WireBackup.xcframework.zip?download=true",
            checksum: "e482a3d22bbf1141ac67ce26a5f1640f3ff7a55873cf18dce7cb29281edb04e0"
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
