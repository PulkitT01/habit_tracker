/// A prompt group with at least one active habit, as the reminder planner sees it.
public struct ReminderGroup: Sendable, Equatable {
    public let prompt: Prompt
    public let isLogged: Bool
    /// Names of habits still unlogged, for the notification text.
    public let pendingHabitNames: [String]

    public init(prompt: Prompt, isLogged: Bool, pendingHabitNames: [String]) {
        self.prompt = prompt
        self.isLogged = isLogged
        self.pendingHabitNames = pendingHabitNames
    }
}
