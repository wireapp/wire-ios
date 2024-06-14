// swift-tools-version: 5.10
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "WireUI",
    products: [
        .library(
            name: "WireUserStatusUI",
            targets: ["WireUserStatusUI"])
    ],
    targets: [
        .target(
            name: "WireUserStatusUI"),
        .testTarget(
            name: "WireUserStatusUITests",
            dependencies: ["WireUserStatusUI"])
    ]
)
