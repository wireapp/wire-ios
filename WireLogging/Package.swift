// swift-tools-version: 6.0

import PackageDescription

let package = Package(
    name: "WireLogging",
    platforms: [.iOS("16.4"), .macOS(.v12)],
    products: [
        .library(name: "WireLogging", targets: ["WireLogging"]),
        .library(name: "WireLoggingSupport", targets: ["WireLoggingSupport"])
    ],
    dependencies: [
        .package(path: "../WirePlugins")
    ],
    targets: [
        .target(name: "WireLogging"),
        .target(
            name: "WireLoggingSupport",
            dependencies: ["WireLogging"],
            plugins: [.plugin(name: "SourceryPlugin", package: "WirePlugins")]
        )
    ]
)

for target in package.targets {
    target.swiftSettings = (target.swiftSettings ?? []) + [
        .enableUpcomingFeature("InternalImportsByDefault"),
        .enableUpcomingFeature("ExistentialAny")
    ]
}
