// swift-tools-version: 6.2

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
            url: "https://github.com/wireapp/wire-avs/releases/download/10.5.10/avs.xcframework.zip",
            checksum: "67ebe389b81a66aaf95fa3cb151c2863728ec4c08b0c6879822ef21aa7fcd1fb"
        )
    ]
)
