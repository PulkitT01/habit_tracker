/// Everything the Stats tab shows, computed from logged entries.
public struct StatsSnapshot: Sendable, Equatable {
    /// Days of history before today needed for 28-day rates whose window may end yesterday.
    public static let historyDays = 28
    public static let sparklineDays = 28

    public let rates: [HabitRates]
    public let trends: [HabitTrend]

    /// - Parameters:
    ///   - habits: habits to show, in display order.
    ///   - recentEntries: entries from at least `historyDays` before `today` through `today`.
    ///   - trendHistories: full logged history of each trend habit, by habit id.
    public init(habits: [Habit], today: Day, recentEntries: [Entry], trendHistories: [String: [Entry]]) {
        let recentValues = Dictionary(grouping: recentEntries, by: \.habitId).mapValues(Self.valuesByDay)
        rates = habits.map { habit in
            HabitRates(habit: habit, values: recentValues[habit.id] ?? [:], today: today)
        }
        trends = habits.filter(\.showsTrend).map { habit in
            HabitTrend(habit: habit, series: TrendSeries(values: Self.valuesByDay(trendHistories[habit.id] ?? [])))
        }
    }

    /// Logged values by day; NULL values are dropped.
    private static func valuesByDay(_ entries: [Entry]) -> [Day: Double] {
        Dictionary(entries.compactMap { entry in entry.value.map { (entry.date, $0) } }, uniquingKeysWith: { latest, _ in latest })
    }
}
