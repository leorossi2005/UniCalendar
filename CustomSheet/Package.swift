// swift-tools-version: 6.4
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "CustomSheet",
    defaultLocalization: "it",
    platforms: [
        .iOS(.v17)
    ],
    products: [
        .library(
            name: "CustomSheet",
            targets: ["CustomSheet"]
        )
    ],
    targets: [
        .target(
            name: "CustomSheet",
            swiftSettings: [
                .enableUpcomingFeature("ApproachableConcurrency"),
            ]
        ),

    ],
    swiftLanguageModes: [.v6]
)
