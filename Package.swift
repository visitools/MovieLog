// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "MovieLog",
    platforms: [
        .macOS(.v13)
    ],
    products: [
        .executable(
            name: "MovieLog",
            targets: ["MovieLog"]
        )
    ],
    targets: [
        .executableTarget(
            name: "MovieLog",
            path: "Sources/MovieLog"
        )
    ]
)
