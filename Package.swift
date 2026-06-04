// swift-tools-version:5.7
import PackageDescription

let package = Package(
    name: "TOAlertViewController",
    platforms: [
        .iOS(.v15)
    ],
    products: [
        .library(name: "TOAlertViewController", targets: ["TOAlertViewController"])
    ],
    dependencies: [
        .package(url: "https://github.com/TimOliver/TORoundedButton", .upToNextMajor(from: "2.1.0"))
    ],
    targets: [
        .target(
            name: "TOAlertViewController",
            dependencies: ["TORoundedButton"],
            path: "TOAlertViewController",
            // The repo keeps headers alongside their sources (for Xcode/CocoaPods),
            // so `include/` holds symlinks to the public headers to give SPM the
            // dedicated public-headers directory it requires. The source folders are
            // added to the header search path so the .m files resolve their imports.
            publicHeadersPath: "include",
            cSettings: [
                .headerSearchPath("."),
                .headerSearchPath("Internal")
            ]
        )
    ]
)
