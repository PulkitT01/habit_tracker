import Foundation

/// Reminder history per day and group, kept in UserDefaults so each follow-up and catch-up is
/// sent at most once, even across sleep and relaunches.
public struct ReminderLog: Sendable, Equatable, Codable {
    /// Keyed by "YYYY-MM-DD.prompt".
    private let records: [String: ReminderRecord]

    public init() {
        records = [:]
    }

    private init(records: [String: ReminderRecord]) {
        self.records = records
    }

    public func record(day: Day, prompt: Prompt) -> ReminderRecord {
        records[Self.key(day, prompt)] ?? .empty
    }

    public func setting(_ record: ReminderRecord, day: Day, prompt: Prompt) -> ReminderLog {
        var updated = records
        updated[Self.key(day, prompt)] = record
        return ReminderLog(records: updated)
    }

    /// Records that a notification was seen, for example when it was clicked. A click that
    /// relaunches the app removes the banner from Notification Center, so without this the
    /// planner would send a catch-up for a reminder you just read.
    public func markingShown(_ kind: ReminderKind, day: Day, prompt: Prompt, at date: Date) -> ReminderLog {
        let current = record(day: day, prompt: prompt)
        let updated = switch kind {
        case .reminder, .catchUp:
            ReminderRecord(shownAt: current.shownAt ?? date, followUpDueAt: current.followUpDueAt, followUpSent: current.followUpSent)
        case .followUp:
            ReminderRecord(shownAt: current.shownAt ?? date, followUpDueAt: current.followUpDueAt ?? date, followUpSent: true)
        }
        return setting(updated, day: day, prompt: prompt)
    }

    /// Drops records for days before `day`.
    public func pruned(before day: Day) -> ReminderLog {
        ReminderLog(records: records.filter { key, _ in
            Day(String(key.prefix(10))).map { $0 >= day } ?? false
        })
    }

    private static func key(_ day: Day, _ prompt: Prompt) -> String {
        "\(day).\(prompt.rawValue)"
    }
}
