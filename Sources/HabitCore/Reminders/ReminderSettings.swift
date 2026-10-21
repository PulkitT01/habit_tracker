/// When reminders fire.
public struct ReminderSettings: Sendable, Equatable {
    public let morning: TimeOfDay
    public let evening: TimeOfDay
    /// The single follow-up comes this long after a reminder if the group is still unlogged.
    public let followUpMinutes: Int

    public init(morning: TimeOfDay, evening: TimeOfDay, followUpMinutes: Int) {
        self.morning = morning
        self.evening = evening
        self.followUpMinutes = followUpMinutes
    }

    public func time(for prompt: Prompt) -> TimeOfDay {
        switch prompt {
        case .morning: morning
        case .evening: evening
        }
    }
}
