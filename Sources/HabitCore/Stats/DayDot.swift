/// A habit's state on one day of the dot strip.
public struct DayDot: Sendable, Equatable, Identifiable {
    public static let weekLength = 7

    public let day: Day
    public let state: DotState

    public var id: Day { day }

    public init(day: Day, state: DotState) {
        self.day = day
        self.state = state
    }

    /// The seven days ending on `last`, oldest first.
    public static func week(for habit: Habit, values: [Day: Double], endingOn last: Day) -> [DayDot] {
        (0..<weekLength).reversed().map { offset in
            let day = last.adding(days: -offset)
            return DayDot(day: day, state: DotState(habit: habit, day: day, value: values[day]))
        }
    }
}
