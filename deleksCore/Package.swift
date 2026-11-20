// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "deleksCore",
    platforms: [.iOS(.v18), .macOS(.v15)],
    products: [
        .library(name: "deleksCore", targets: ["deleksCore"])
    ],
    targets: [
        .target(name: "deleksCore"),
        .testTarget(name: "deleksCoreTests", dependencies: ["deleksCore"]),
    ]
)
