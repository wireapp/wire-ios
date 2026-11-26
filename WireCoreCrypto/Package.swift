// swift-tools-version: 6.0

import Foundation
import PackageDescription

// Temporary local package replacing integration of CoreCrypto via Carthage
let package = Package(
    name: "WireCoreCrypto",
    platforms: [.iOS(.v17), .macOS(.v12)],
    products: [
        .library(
            name: "WireCoreCrypto",
            targets: ["WireCoreCrypto"]
        ),
        .library(
            name: "WireCoreCryptoUniffi",
            targets: ["WireCoreCryptoUniffi"]
        )
    ],
    dependencies: [],
    targets: [
        // Don't go below 11.0.1. It contains the cross-process fixes the app, NSE and share extension rely on
        // (WPB-27280): Proteus/MLS caches are cleared when another process wrote to the keystore
        // (core-crypto#2844), and the iOS salt migration runs under the cross-process lock (core-crypto#2852).
        .binaryTarget(
            name: "WireCoreCrypto",
            url: "https://github.com/wireapp/core-crypto/releases/download/v11.0.1/WireCoreCrypto.xcframework.zip",
            checksum: "74fb24ad8514d5a0c2112391247886afa2abc1ca4e16cf287f8a78772548e291"
        ),
        // this is an internal dependency to WireCoreCrypto but currently needs to explicitly
        // added as a dependency due to limitations of Swift packages.
        .binaryTarget(
            name: "WireCoreCryptoUniffi",
            url: "https://github.com/wireapp/core-crypto/releases/download/v11.0.1/WireCoreCryptoUniffi.xcframework.zip",
            checksum: "e7d7f81d64a1e3768c488367f18a87116e7e6dca4b133ae105f76bdb93859f62"
        )
    ]
)
