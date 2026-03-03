// swift-tools-version: 6.0

import Foundation
import PackageDescription

// Temporary local package replacing integration of AVS via Carthage
let package = Package(
    name: "WireAVS",
    platforms: [.iOS("16.4"), .macOS(.v12)],
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
            url: "https://github.com/wireapp/wire-avs/releases/download/10.1.47/avs.xcframework.zip",
            checksum: "89119ca5e8a510d99eb93bd15a35202c7e2f069f9349dd92cf2acf908eb0e2cd"
        )
    ]
)
