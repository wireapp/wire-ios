// swift-tools-version: 6.0

import Foundation
import PackageDescription

// Temporary local package replacing integration of AVS via Carthage
let package = Package(
    name: "WireAVS",
    platforms: [.iOS("17.0"), .macOS(.v12)],
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
            url: "https://github.com/wireapp/wire-avs/releases/download/10.1.64/avs.xcframework.zip",
            checksum: "fa9d90ab29bb3e2deeab0752ea25237adb7d1ed79dcd5ce3802c4291ee09b7e8"
        )
    ]
)
