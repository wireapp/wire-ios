// swift-tools-version: 5.10
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "ConversationList",
    defaultLocalization: "en",
    platforms: [.iOS(.v15)],
    products: [
        .library(name: "ConversationList", targets: ["ConversationList"])
    ],
    targets: [
        .target(name: "ConversationList", path: "./Sources")
    ]
)
