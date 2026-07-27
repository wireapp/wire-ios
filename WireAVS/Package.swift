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
            url: "https://github.com/wireapp/wire-avs/releases/download/10.4.28/avs.xcframework.zip",
            checksum: "ceaefc593a00ae9a168611aeabf13de0f97d0cb6fe50c26ac40b289c98e3b7d6"
        )
    ]
)
