// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "NativeDropdown",
    platforms: [.iOS(.v17)],
    products: [
        .library(name: "NativeDropdown", targets: ["NativeDropdown"])
    ],
    targets: [
        .target(name: "NativeDropdown"),
        .testTarget(
            name: "NativeDropdownTests",
            dependencies: ["NativeDropdown"],
            path: "PopOverDropDownTests"
        )
    ]
)
