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
            url: "https://github.com/wireapp/wire-avs/releases/download/10.6.8/avs.xcframework.zip",
            checksum: "e5907ae4a89644c39c54685a08de161178658830e3a2ac8bf1057af571d9dbe2"
        )
    ]
)
