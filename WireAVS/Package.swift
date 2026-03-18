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
            url: "https://github.com/wireapp/wire-avs/releases/download/10.1.51/avs.xcframework.zip",
            checksum: "9e7d7c0dd553a5b624d8bb29f2d40997fe4e8c2fae59930ad7febe3d6dee237e"
<<<<<<< HEAD

=======
>>>>>>> e86a1847b4 (chore: bump AVS version - WPB-24126 (#4448))
        )
    ]
)
