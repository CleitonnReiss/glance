// swift-tools-version: 5.7
import PackageDescription

let package = Package(
    name: "Glance",
    platforms: [
        .macOS(.v12)
    ],
    products: [
        .executable(name: "Glance", targets: ["Glance"])
    ],
    dependencies: [
        .package(url: "https://github.com/sparkle-project/Sparkle", from: "2.6.0")
    ],
    targets: [
        .executableTarget(
            name: "Glance",
            dependencies: [
                .product(name: "Sparkle", package: "Sparkle")
            ],
            path: "glance",
            exclude: [
                "Info.plist",
                "glance.entitlements",
                "glanceicon.icon"
            ],
            resources: [
                .process("Assets.xcassets"),
                .process("Resources"),
                .process("Models")
            ]
        )
    ]
)
