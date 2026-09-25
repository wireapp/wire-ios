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
        .binaryTarget(
            name: "WireCoreCrypto",
            url: "https://github.com/wireapp/core-crypto/releases/download/v10.5.3/WireCoreCrypto.xcframework.zip",
            checksum: "38d6ddbc3fee9ddbc6052c5446c822c6ef9148baf2465dabf4509dcd22710e2e"
        ),
        // this is an internal dependency to WireCoreCrypto but currently needs to explicitly
        // added as a dependency due to limitations of Swift packages.
        .binaryTarget(
            name: "WireCoreCryptoUniffi",
            url: "https://github.com/wireapp/core-crypto/releases/download/v10.5.3/WireCoreCryptoUniffi.xcframework.zip",
            checksum: "048fcd212f4f66c50466fe5a3d23f162004f8e58b39ce0f8b49ce1c195109848"
        )
    ]
)
