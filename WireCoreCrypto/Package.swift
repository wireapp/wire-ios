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
            url: "https://github.com/wireapp/core-crypto/releases/download/v10.5.4/WireCoreCrypto.xcframework.zip",
            checksum: "9ef0e0c7a36e5fa1b2850a6293e79e9dffa5099cfc74329b753eed614e9a9e79"
        ),
        // this is an internal dependency to WireCoreCrypto but currently needs to explicitly
        // added as a dependency due to limitations of Swift packages.
        .binaryTarget(
            name: "WireCoreCryptoUniffi",
            url: "https://github.com/wireapp/core-crypto/releases/download/v10.5.4/WireCoreCryptoUniffi.xcframework.zip",
            checksum: "a7a24cd536c909ec30b2e00ac74e768dc97d132d7fd49f9708d87cfcde073550"
        )
    ]
)
