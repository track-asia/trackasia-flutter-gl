// swift-tools-version: 5.9
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "trackasia_gl",
    platforms: [
        .iOS("12.0"),
    ],
    products: [
        .library(name: "trackasia-gl", targets: ["trackasia_gl"])
    ],
    dependencies: [
        // When updating the dependency version,
        // make sure to also update the version in trackasia_gl.podspec.
        .package(url: "https://github.com/track-asia/trackasia-native.git", tag: "ios-v2.0.3"),
    ],
    targets: [
        .target(
            name: "trackasia_gl",
            dependencies: [
                .product(name: "Trackasia", package: "trackasia-native")
            ],
            cSettings: [
                .headerSearchPath("include/trackasia_gl")
            ]
        )
    ]
)
