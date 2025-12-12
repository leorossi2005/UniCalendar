// swift-tools-version: 6.2
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "UnivrCore",
    defaultLocalization: "it",
    platforms: [
        .iOS(.v17),
        .macOS(.v14)
    ],
    products: [
        .library(
            name: "UnivrCore",
            type: .static,
            targets: ["UnivrCore"]
        ),
    ],
    targets: [
        .target(
            name: "UnivrCore",
            resources: [
                .process("Localizable.xcstrings")
            ],
            swiftSettings: [
                .enableUpcomingFeature("StrictConcurrency")
            ]
        ),
        //.testTarget(
        //    name: "UnivrCoreTests",
        //    dependencies: ["UnivrCore"]
        //)
    ]
)
