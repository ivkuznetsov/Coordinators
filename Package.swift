// swift-tools-version: 5.6
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "Coordinators",
    platforms: [
        .macOS(.v12),
        .iOS(.v15)
    ],
    products: [
        .library(name: "Coordinators",
                 targets: ["Coordinators"]),
    ],
    dependencies: [],
    targets: [
        .target(name: "Coordinators",
                dependencies: [])
    ]
)
