/// A trend habit (such as weight) with its EWMA series.
public struct HabitTrend: Sendable, Equatable, Identifiable {
    public let habit: Habit
    public let series: TrendSeries

    public var id: String { habit.id }

    public init(habit: Habit, series: TrendSeries) {
        self.habit = habit
        self.series = series
    }
}
