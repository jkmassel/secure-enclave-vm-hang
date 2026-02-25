// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "secure-enclave-vm-hang",
    platforms: [.macOS(.v13)],
    targets: [
        .executableTarget(name: "secure-enclave-vm-hang")
    ]
)
