// swift-tools-version: 6.2

import PackageDescription

let package = Package(
  name: "Tama",
  platforms: [
    .macOS(.v15)
  ],
  products: [
    .executable(name: "Tama", targets: ["Tama"])
  ],
  targets: [
    .target(name: "TamaShared"),
    .target(
      name: "PetOverlay",
      dependencies: ["TamaShared"],
      resources: [.copy("Resources/Sterling")]
    ),
    .executableTarget(name: "Tama", dependencies: ["PetOverlay", "TamaShared"]),
    .executableTarget(
      name: "TamaChecks",
      dependencies: ["PetOverlay", "TamaShared"],
      path: "Tests/TamaChecks"
    ),
    .testTarget(name: "TamaSharedTests", dependencies: ["TamaShared"]),
    .testTarget(name: "PetOverlayTests", dependencies: ["PetOverlay", "TamaShared"]),
  ]
)
