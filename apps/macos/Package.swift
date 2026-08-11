// swift-tools-version: 6.0

import PackageDescription

let package = Package(
    name: "ReadyDownloader",
    platforms: [.macOS(.v14)],
    products: [
        .executable(name: "ReadyDownloader", targets: ["ReadyDownloader"])
    ],
    targets: [
        .executableTarget(name: "ReadyDownloader"),
        .testTarget(name: "ReadyDownloaderTests", dependencies: ["ReadyDownloader"])
    ]
)
