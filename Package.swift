// swift-tools-version:6.0
import PackageDescription

let package = Package(
    name: "AcademicHelper",
    platforms: [
        .macOS(.v14)
    ],
    products: [
        .executable(
            name: "AcademicHelper",
            targets: ["AcademicHelper"]
        )
    ],
    dependencies: [],
    targets: [
        .executableTarget(
            name: "AcademicHelper",
            dependencies: [],
            swiftSettings: [
                .enableExperimentalFeature("StrictConcurrency")
            ]
        ),
        .testTarget(
            name: "AcademicHelperTests",
            dependencies: ["AcademicHelper"]
        )
    ]
)
