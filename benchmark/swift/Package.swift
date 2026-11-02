// swift-tools-version:5.9
import PackageDescription
let package = Package(
    name: "bench",
    platforms: [.macOS(.v14)],
    dependencies: [.package(url: "https://github.com/openhorizon-labs/sapient-swift", exact: "0.6.9")],
    targets: [.executableTarget(name: "bench", dependencies: [.product(name: "Sapient", package: "sapient-swift")])]
)
