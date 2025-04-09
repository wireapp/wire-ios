// swift-tools-version: 6.0

import Foundation
import PackageDescription

// Temporary local package replacing integration of AVS via Carthage
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
            url: "https://github.com/wireapp/wire-avs/releases/download/10.0.37/avs.xcframework.zip",
            checksum: "9926ab473cce99379e5e9aea6c76221d5c489284a92438fea320ef3a23ab0201"
        )
    ]
)
