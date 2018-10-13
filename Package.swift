// swift-tools-version:4.2
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "GPSLocationTagger",
    products: [
        // Products define the executables and libraries produced by a package, and make them visible to other packages.
        .executable(name: "gps2location", targets: ["gps2location"]),
        .library(
            name: "GPSLocationTagger",
            targets: ["GPSLocationTagger"]),

    ],
    dependencies: [
        // Dependencies declare other packages that this package depends on.
        // .package(url: /* package url */, from: "1.0.0"),
        .package(url: "https://github.com/apple/swift-package-manager.git", from: "0.1.0")
    ],
    targets: [
        // Targets are the basic building blocks of a package. A target can define a module or a test suite.
        // Targets can depend on other targets in this package, and on products in packages which this package depends on.
        .target(
            name: "gps2location",
            dependencies: ["GPSLocationTagger", "Utility"]),

        .target(
            name: "GPSLocationTagger",
            dependencies: ["Utility"]),
        .testTarget(
            name: "GPSLocationTaggerTests",
            dependencies: ["GPSLocationTagger"]),
    ]
)
