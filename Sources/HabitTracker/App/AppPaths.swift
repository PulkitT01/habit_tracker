import Foundation
import HabitCore

/// Where the config and database live: ~/Library/Application Support/HabitTracker for the
/// installed app, …/HabitTracker-Dev for `make run` (and a bare `swift run`), so development
/// never touches real data.
struct AppPaths {
    let folder: URL

    var config: URL { folder.appending(path: HabitConfig.fileName) }
    var database: URL { folder.appending(path: AppDatabase.fileName) }

    /// The `make run` build (bundle id ending in ".dev"), or a bare binary without a bundle.
    static var isDevBuild: Bool {
        Bundle.main.bundleIdentifier?.hasSuffix(".dev") ?? true
    }

    static var current: AppPaths {
        let name = isDevBuild ? "HabitTracker-Dev" : "HabitTracker"
        return AppPaths(folder: URL.applicationSupportDirectory.appending(path: name, directoryHint: .isDirectory))
    }
}
