// swift-tools-version: 6.0

import Foundation
import PackageDescription

// Temporary local package replacing integration of AVS via Carthage
let package = Package(
    name: "WireAVS",
    platforms: [.iOS(.v17), .macOS(.v12)],
    products: [
        .library(
            name: "WireAVS",
            targets: ["WireAVS"]
        )
    ],
    dependencies: [],
    targets: [
        .binaryTarget(
            name: "WireAVS",
            url: "https://github.com/wireapp/wire-avs/releases/download/10.4.5/avs.xcframework.zip",
            checksum: "2061baefbc05c6d27e8243d34c2f24e3f4f2277625aaeaf332c0b2c0a0ef8110"
        )
    ]
)
