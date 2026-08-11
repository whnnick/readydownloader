// swift-tools-version: 5.10

import PackageDescription

let package = Package(
    name: "ReadyDownloader",
    platforms: [.macOS(.v13)],
    products: [
        .executable(name: "ReadyDownloader", targets: ["ReadyDownloader"])
    ],
    targets: [
        .executableTarget(name: "ReadyDownloader"),
        .testTarget(name: "ReadyDownloaderTests", dependencies: ["ReadyDownloader"])
    ]
)
