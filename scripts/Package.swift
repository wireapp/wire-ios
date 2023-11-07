// swift-tools-version: 5.9
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "Scripts",
    products: [
        .library(name: "Dummy", targets: ["Dummy"])
    ],
    dependencies: [
        .package(url: "https://github.com/realm/SwiftLint.git", exact: "0.53.0"),
    ],
    targets: [
        .target(
            name: "Dummy",
            plugins: [.plugin(name: "SwiftLintPlugin", package: "SwiftLint")]
        )
    ]
)
