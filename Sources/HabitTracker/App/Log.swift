import Foundation
import os

/// Loggers for Console.app (filter by the bundle identifier).
nonisolated enum Log {
    private static let subsystem = Bundle.main.bundleIdentifier ?? "HabitTracker"

    static let app = Logger(subsystem: subsystem, category: "app")
    static let store = Logger(subsystem: subsystem, category: "store")
    static let reminders = Logger(subsystem: subsystem, category: "reminders")
}
