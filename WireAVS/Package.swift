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
<<<<<<< HEAD
            url: "https://github.com/wireapp/wire-avs/releases/download/10.1.57/avs.xcframework.zip",
            checksum: "2231a0582a2f7217c2a7a3d9884dbe314e1dcc04ea3ee78c3e78937f9b78b039"
=======
            url: "https://github.com/wireapp/wire-avs/releases/download/10.1.65/avs.xcframework.zip",
            checksum: "5553b0132cef04bde820d6d60d54ec1e0bd026866be937dbfb888ff1b0f4ddc7"
>>>>>>> 2559c3a8f1 (chore: bump AVS - WPB-24869 (#4629))
        )
    ]
)
