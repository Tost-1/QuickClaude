// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "QuickClaude",
    platforms: [.macOS(.v14)],
    dependencies: [
        .package(url: "https://github.com/gonzalezreal/swift-markdown-ui", from: "2.4.0"),
        .package(url: "https://github.com/mgriebling/SwiftMath", from: "1.4.0")
    ],
    targets: [
        .executableTarget(
            name: "QuickClaude",
            dependencies: [
                .product(name: "MarkdownUI", package: "swift-markdown-ui"),
                .product(name: "SwiftMath", package: "SwiftMath"),
            ],
            path: "Sources/QuickClaude"
        )
    ],
    swiftLanguageModes: [.v5]
)
