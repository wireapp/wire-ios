// swift-tools-version: 6.0
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "WireLogging",
    platforms: [.iOS(.v16), .macOS(.v12)],
    products: [
        .library(name: "WireLogging", targets: ["WireLogging"]),
        .library(name: "WireLoggingSupport", targets: ["WireLoggingSupport"]),
        .library(name: "WireLegacyLogging", targets: ["WireLegacyLogging"])
    ],
    dependencies: [
        .package(url: "https://github.com/swiftlang/swift-docc-plugin", from: "1.1.0"),
        .package(path: "../WirePlugins")
    ],
    targets: [
        .target(
            name: "WireLogging",
            dependencies: ["WireLegacyLogging"]
        ),
        .target(
            name: "WireLoggingSupport",
            dependencies: ["WireLogging"],
            plugins: [.plugin(name: "SourceryPlugin", package: "WirePlugins")]
        ),
        .testTarget(
            name: "WireLoggingTests",
            dependencies: ["WireLogging", "WireLoggingSupport"]
        ),

        .target(name: "WireLegacyLogging")
    ]
)

for target in package.targets {
    target.swiftSettings = (target.swiftSettings ?? []) + [
        .enableUpcomingFeature("InternalImportsByDefault"),
        .enableUpcomingFeature("FullTypedThrows"),
        .enableUpcomingFeature("ExistentialAny")
    ]
}
