import Foundation

/// A notification the app should have pending (or deliver now).
public struct PlannedNotification: Sendable, Equatable, Identifiable {
    public let kind: ReminderKind
    public let day: Day
    public let prompt: Prompt
    /// nil means deliver immediately.
    public let fireDate: Date?
    public let habitNames: [String]

    public init(kind: ReminderKind, day: Day, prompt: Prompt, fireDate: Date?, habitNames: [String]) {
        self.kind = kind
        self.day = day
        self.prompt = prompt
        self.fireDate = fireDate
        self.habitNames = habitNames
    }

    /// Deterministic, so re-adding replaces the pending request instead of duplicating it.
    public var id: String { Self.id(kind, day, prompt) }

    public static func id(_ kind: ReminderKind, _ day: Day, _ prompt: Prompt) -> String {
        "\(kind.rawValue).\(day).\(prompt.rawValue)"
    }
}
