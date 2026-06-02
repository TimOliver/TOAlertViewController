// swift-tools-version:5.5
import PackageDescription

let package = Package(
    name: "TOAlertViewController",
    platforms: [
        .iOS(.v15)
    ],
    products: [
        .library(
            name: "TOAlertViewController",
            type: .static,
            targets: ["TOAlertViewController"]
        )
    ],
    dependencies: [
        .package(
            url: "https://github.com/TimOliver/TORoundedButton",
            from: "2.1.0"
        )
    ],
    targets: [
        .target(
            name: "TOAlertViewController",
            dependencies: ["TORoundedButton"],
            path: "spm",
            cSettings: [
                .headerSearchPath("Internal")
            ]
        ),
        .testTarget(
            name: "TOAlertViewControllerTests",
            dependencies: ["TOAlertViewController"],
            path: "TOAlertViewControllerTests",
            exclude: ["Info.plist"]
        )
    ]
)
