// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "ClankersCore",
    platforms: [.iOS(.v18), .macOS(.v15)],
    products: [
        .library(name: "ClankersCore", targets: ["ClankersCore"])
    ],
    targets: [
        .target(name: "ClankersCore"),
        .testTarget(name: "ClankersCoreTests", dependencies: ["ClankersCore"]),
    ]
)
