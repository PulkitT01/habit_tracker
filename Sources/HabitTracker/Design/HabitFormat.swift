import Foundation
import HabitCore

/// Display formatting for habit values (storage formats live in HabitCore).
enum HabitFormat {
    static func value(_ value: Double, of habit: Habit) -> String {
        switch habit.type {
        case .binary, .count:
            value.formatted(.number.precision(.fractionLength(0)).grouping(.never))
        case .number:
            value.formatted(.number.precision(.fractionLength(habit.decimals)).grouping(.never))
        case .sleep:
            hours(value)
        }
    }

    /// "7h 45m".
    static func hours(_ hours: Double) -> String {
        Duration.seconds(hours * 3600).formatted(.units(allowed: [.hours, .minutes], width: .narrow))
    }

    /// "≥5" for habits with a minimum target.
    static func target(of habit: Habit) -> String? {
        habit.minTarget.map { "≥\(value($0, of: habit))" }
    }

    static func percent(_ fraction: Double?) -> String {
        fraction.map { $0.formatted(.percent.precision(.fractionLength(0))) } ?? "—"
    }
}
