// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "ScarabVaultLogic",
    platforms: [.macOS(.v14)],
    products: [.library(name: "ScarabVaultLogic", targets: ["ScarabVault"])],
    targets: [
        .target(name: "ScarabVault", path: "Sources", exclude: ["ScarabVaultApp.swift", "MechanismView.swift", "CollectionViews.swift", "Theme.swift"], sources: ["Puzzle.swift", "Progress.swift"]),
        .testTarget(name: "ScarabVaultLogicTests", dependencies: ["ScarabVault"], path: "Tests")
    ],
    swiftLanguageModes: [.v6]
)
