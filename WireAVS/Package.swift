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
            url: "https://github.com/wireapp/wire-avs/releases/download/10.0.35/avs.xcframework.zip",
            checksum: "f7a2a8005ddbaaa2747be03f74e88695a84c5dfb306bad833377e329abf4a717"
        )
    ]
)
