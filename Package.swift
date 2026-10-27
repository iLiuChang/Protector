// swift-tools-version:5.9

import PackageDescription

let package = Package(
    name: "Protector",
    platforms: [
        .iOS(.v12),
        .macOS(.v10_13),
        .tvOS(.v12),
        .watchOS(.v4),
        .visionOS(.v1),
    ],
    products: [
        .library(name: "Protector", targets: ["Protector"]),
    ],
    targets: [
        .target(
            name: "Protector",
            path: "Sources",
            resources: [.copy("PrivacyInfo.xcprivacy")]
        )
    ]
)
