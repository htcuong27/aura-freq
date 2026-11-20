// swift-tools-version: 6.0
import PackageDescription

let package = Package(name: "AuraFreq", platforms: [.macOS(.v15)], targets: [
    .executableTarget(name: "AuraFreq"),
    .testTarget(name: "AuraFreqTests", dependencies: ["AuraFreq"])
])
