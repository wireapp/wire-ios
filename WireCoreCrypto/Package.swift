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
<<<<<<< HEAD
            url: "https://github.com/wireapp/core-crypto/releases/download/v10.4.0/WireCoreCrypto.xcframework.zip",
            checksum: "1dba6e0579dc2ec03cee335fbc6a1f0f85cc928339aee215d7afbf45eb874291"
=======
            url: "https://github.com/wireapp/core-crypto/releases/download/v10.5.1/WireCoreCrypto.xcframework.zip",
            checksum: "94f1bb14cfdaf846e2e4798e5e9bd36742db732c7c2586e3d0ce5aac8bb53024"
>>>>>>> efc5d879f7 (chore: update CC to 10.5.1 - WPB-28566 (#5198))
        ),
        // this is an internal dependency to WireCoreCrypto but currently needs to explicitly
        // added as a dependency due to limitations of Swift packages.
        .binaryTarget(
            name: "WireCoreCryptoUniffi",
<<<<<<< HEAD
            url: "https://github.com/wireapp/core-crypto/releases/download/v10.4.0/WireCoreCryptoUniffi.xcframework.zip",
            checksum: "04230e60596473955aab52de8ae03789bc5ea63a0f044a963ce6ee100bc887a6"
=======
            url: "https://github.com/wireapp/core-crypto/releases/download/v10.5.1/WireCoreCryptoUniffi.xcframework.zip",
            checksum: "0530c48824e86ee15eefe55b0de86f34a3f78e1486d2f149e28ee23e501814aa"
>>>>>>> efc5d879f7 (chore: update CC to 10.5.1 - WPB-28566 (#5198))
        )
    ]
)
