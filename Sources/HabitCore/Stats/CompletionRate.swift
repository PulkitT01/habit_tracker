/// Share of eligible days a habit was done, over a rolling window.
///
/// Eligible days are those the habit is active. The window ends today once today is logged and
/// yesterday until then, so the rate doesn't dip every morning. Unlogged past days count as not
/// done; `notLogged` keeps them separate from explicit misses.
public struct CompletionRate: Sendable, Equatable {
    public let done: Int
    public let missed: Int
    public let notLogged: Int

    public init(done: Int, missed: Int, notLogged: Int) {
        self.done = done
        self.missed = missed
        self.notLogged = notLogged
    }

    /// - Parameter values: logged (non-NULL) values by day.
    public init(habit: Habit, values: [Day: Double], today: Day, days: Int) {
        let last = values[today] == nil ? today.adding(days: -1) : today
        let states = (0..<days).map { offset in
            let day = last.adding(days: -offset)
            return DotState(habit: habit, day: day, value: values[day])
        }
        self.init(
            done: states.count { $0 == .done },
            missed: states.count { $0 == .missed },
            notLogged: states.count { $0 == .notLogged }
        )
    }

    public var eligible: Int { done + missed + notLogged }

    /// nil when no day in the window is eligible.
    public var fraction: Double? {
        eligible == 0 ? nil : Double(done) / Double(eligible)
    }
}
