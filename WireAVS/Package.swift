// swift-tools-version: 6.0

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
<<<<<<< HEAD
            url: "https://github.com/wireapp/wire-avs/releases/download/10.4.5/avs.xcframework.zip",
            checksum: "2061baefbc05c6d27e8243d34c2f24e3f4f2277625aaeaf332c0b2c0a0ef8110"
=======
            url: "https://github.com/wireapp/wire-avs/releases/download/10.3.23/avs.xcframework.zip",
            checksum: "1b93474d2a7b2978674e145d41129c6eb346493b468182a43cb61298f9447f9c"
>>>>>>> ba33b8d428 (chore: bump AVS 10.3.23 - WPB-25715 🍒 (#4900))
        )
    ]
)
