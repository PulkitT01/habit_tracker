/// One habit's row in the Stats tab: the last seven days and rolling 7- and 28-day rates.
public struct HabitRates: Sendable, Equatable, Identifiable {
    public static let shortWindow = 7
    public static let longWindow = 28

    public let habit: Habit
    public let dots: [DayDot]
    public let week: CompletionRate
    public let month: CompletionRate

    public var id: String { habit.id }

    public init(habit: Habit, values: [Day: Double], today: Day) {
        self.habit = habit
        dots = DayDot.week(for: habit, values: values, endingOn: today)
        week = CompletionRate(habit: habit, values: values, today: today, days: Self.shortWindow)
        month = CompletionRate(habit: habit, values: values, today: today, days: Self.longWindow)
    }
}
