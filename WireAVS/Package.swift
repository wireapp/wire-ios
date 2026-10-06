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
            path: "../../wire-avs/build/dist/xc/avs.xcframework" // TODO: undo changes
            // path: "build/avs.xcframework"
        )
    ]
)
