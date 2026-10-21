/// Logging progress for one day. Drives the menu-bar icon, the yesterday banner and reminders.
///
/// A group counts as logged when every active habit in it has a value, or when Done was pressed
/// for it. The second rule lets a skipped measurement (no weigh-in today) still finish the day.
public struct DayStatus: Sendable, Equatable {
    public let day: Day
    public let groups: [Prompt: LogState]
    public let loggedHabitCount: Int
    public let activeHabitCount: Int

    /// - Parameters:
    ///   - habits: all configured habits; inactive ones are ignored.
    ///   - loggedHabitIDs: habits with a non-NULL value on `day`.
    ///   - doneMarks: groups finished with the Done button on `day`.
    public init(day: Day, habits: [Habit], loggedHabitIDs: Set<String>, doneMarks: Set<Prompt>) {
        let active = habits.filter { $0.isActive(on: day) }
        self.day = day
        self.activeHabitCount = active.count
        self.loggedHabitCount = active.count { loggedHabitIDs.contains($0.id) }
        self.groups = Dictionary(uniqueKeysWithValues: Prompt.allCases.map { prompt in
            let inGroup = active.filter { $0.prompt == prompt }
            let loggedCount = inGroup.count { loggedHabitIDs.contains($0.id) }
            let state: LogState =
                if inGroup.isEmpty {
                    .notApplicable
                } else if doneMarks.contains(prompt) || loggedCount == inGroup.count {
                    .logged
                } else if loggedCount > 0 {
                    .partial
                } else {
                    .empty
                }
            return (prompt, state)
        })
    }

    public func state(of prompt: Prompt) -> LogState {
        groups[prompt] ?? .notApplicable
    }

    /// `.logged` once every group with habits is logged; `.empty` while nothing is logged or marked.
    public var overall: LogState {
        let applicable = groups.values.filter { $0 != .notApplicable }
        if applicable.isEmpty { return .notApplicable }
        if applicable.allSatisfy({ $0 == .logged }) { return .logged }
        if applicable.allSatisfy({ $0 == .empty }) { return .empty }
        return .partial
    }
}
