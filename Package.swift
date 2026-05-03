// swift-tools-version: 6.2
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "PokerModel",
    platforms: [
        .iOS(.v17),
        .macOS(.v12),
    ],
    products: [
        .library(
            name: "PokerModel",
            targets: ["PokerModel"]
        ),
    ],
    targets: [
        .target(
            name: "PokerModel"
        ),
        .testTarget(
            name: "PokerModelTests",
            dependencies: ["PokerModel"]
        ),
    ]
)
