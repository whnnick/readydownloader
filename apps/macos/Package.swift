// swift-tools-version: 6.0

import PackageDescription

let package = Package(
    name: "YouTubeDlpDownloader",
    platforms: [.macOS(.v14)],
    products: [
        .executable(name: "YouTubeDlpDownloader", targets: ["YouTubeDlpDownloader"])
    ],
    targets: [
        .executableTarget(name: "YouTubeDlpDownloader"),
        .testTarget(name: "YouTubeDlpDownloaderTests", dependencies: ["YouTubeDlpDownloader"])
    ]
)
