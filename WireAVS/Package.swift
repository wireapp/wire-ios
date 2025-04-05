// swift-tools-version: 6.0

import Foundation
import PackageDescription

// Temporary local package replacing integration of CoreCrypto via Carthage
let package = Package(
    name: "WireAVS",
    platforms: [.iOS(.v16), .macOS(.v12)],
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
            url: "https://github.com/wireapp/wire-avs/releases/download/10.0.36/avs.xcframework.zip",
            checksum: "4a53f72bafa14d9911bb973c00f0b48c2c5c8da6a110fcabc616b74f7e0bd101"
        )
    ]
)
