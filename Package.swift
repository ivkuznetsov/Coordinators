// swift-tools-version: 5.8
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "Coordinators",
    platforms: [
        .iOS(.v16)
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
