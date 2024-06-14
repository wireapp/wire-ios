// swift-tools-version: 5.10
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "WireUI",
    defaultLocalization: "en",
    platforms: [
        .iOS(.v15),
        .macOS(.v12)
    ],
    products: [
        .library(
            name: "WireReusableUIComponents",
            targets: ["WireReusableUIComponents"])
    ],
    targets: [
        .target(
            name: "WireReusableUIComponents"),
        .testTarget(
            name: "WireReusableUIComponentsTests",
            dependencies: ["WireReusableUIComponents"])
    ]
)
