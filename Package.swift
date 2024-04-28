// swift-tools-version: 5.9

import PackageDescription

let package = Package(
    name: "IAPKit",
    platforms: [.iOS(.v17)],
    products: [
        .library(
            name: "IAPKit",
            targets: ["IAPKit"]
        ),
        .library(
            name: "IAPKitImpl",
            targets: ["IAPKitImpl"]
        )
    ],
    dependencies: [
        .package(path: "../Utils"),
    ],
    targets: [
        .target(
            name: "IAPKit",
            dependencies: ["Utils"]
        ),
        .target(
            name: "IAPKitImpl",
            dependencies: ["Utils", "IAPKit"]
        ),
    ]
)
