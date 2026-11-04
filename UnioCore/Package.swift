// swift-tools-version: 6.4
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "UnioCore",
    defaultLocalization: "it",
    platforms: [
        .iOS(.v17),
        .macOS(.v14)
    ],
    products: [
        .library(
            name: "UnioCore",
            type: .static,
            targets: ["UnioCore"]
        ),
    ],
    targets: [
        .target(
            name: "UnioCore",
            resources: [
                .process("Localizable.xcstrings")
            ],
            swiftSettings: [
                .enableUpcomingFeature("ApproachableConcurrency"),
            ],
        )
    ],
    swiftLanguageModes: [.v6]
)
