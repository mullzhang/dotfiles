// swift-tools-version: 6.0

import PackageDescription

let package = Package(
    name: "ClipboardToWindow",
    platforms: [
        .macOS(.v13)
    ],
    products: [
        .executable(name: "clipboard-to-window", targets: ["ClipboardToWindow"])
    ],
    targets: [
        .executableTarget(name: "ClipboardToWindow")
    ]
)
