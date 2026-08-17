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
            url: "https://github.com/wireapp/wire-avs/releases/download/10.5.8/avs.xcframework.zip",
            checksum: "0d58623fdf25570477ca0bc9018d7cf2767c10804be6740b2e6c78fa11ab675b"
        )
    ]
)
