import Foundation
import HabitCore

/// A reminder notification the user clicked.
struct OpenedReminder: Sendable {
    let day: Day?
    let prompt: Prompt?
    let kind: ReminderKind?
    let deliveredAt: Date
}
