// swift-tools-version: 6.2
import PackageDescription

let package = Package(
    name: "HabitTracker",
    platforms: [.macOS(.v14)],
    products: [
        .executable(name: "HabitTracker", targets: ["HabitTracker"]),
    ],
    dependencies: [
        .package(url: "https://github.com/groue/GRDB.swift.git", from: "7.11.0"),
        // Opens and closes the MenuBarExtra window from code (notification clicks, Done).
        // Pinned exactly: on macOS 27 it relies on guarded private AppKit calls.
        .package(url: "https://github.com/orchetect/MenuBarExtraAccess.git", exact: "1.3.1"),
    ],
    targets: [
        // Pure logic and persistence: no SwiftUI, fully unit tested.
        .target(
            name: "HabitCore",
            dependencies: [.product(name: "GRDB", package: "GRDB.swift")]
        ),
        // The menu-bar app. UI code is main-actor isolated by default.
        .executableTarget(
            name: "HabitTracker",
            dependencies: [
                "HabitCore",
                .product(name: "MenuBarExtraAccess", package: "MenuBarExtraAccess"),
            ],
            swiftSettings: [
                .defaultIsolation(MainActor.self),
                .enableUpcomingFeature("InferIsolatedConformances"),
            ]
        ),
        .testTarget(
            name: "HabitCoreTests",
            dependencies: [
                "HabitCore",
                .product(name: "GRDB", package: "GRDB.swift"),
            ]
        ),
    ]
)
