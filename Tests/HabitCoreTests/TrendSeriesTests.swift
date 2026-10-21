import Testing
@testable import HabitCore

@Suite struct TrendSeriesTests {
    private let start: Day

    init() throws {
        start = try day("2026-08-01")
    }

    private func series(_ values: [Double], every step: Int = 1) -> TrendSeries {
        TrendSeries(values: Dictionary(uniqueKeysWithValues: values.enumerated().map { (start.adding(days: $0.offset * step), $0.element) }))
    }

    private func isClose(_ lhs: Double?, _ rhs: Double, tolerance: Double = 1e-9) -> Bool {
        lhs.map { abs($0 - rhs) <= tolerance } ?? false
    }

    @Test func matchesHandComputedEWMA() {
        // pandas: pd.Series([80, 81, 79]).ewm(alpha=0.1, adjust=False).mean() → 80, 80.1, 79.99
        let trends = series([80, 81, 79]).points.map(\.trend)
        #expect(trends.count == 3)
        #expect(isClose(trends[0], 80))
        #expect(isClose(trends[1], 80.1))
        #expect(isClose(trends[2], 79.99))
    }

    @Test func keepsRawValuesAndSortsByDay() throws {
        let trend = TrendSeries(values: try values([("2026-08-03", 79), ("2026-08-01", 80), ("2026-08-02", 81)]))
        #expect(trend.points.map(\.value) == [80, 81, 79])
        #expect(try trend.latest?.day == day("2026-08-03"))
    }

    @Test func ignoresValuesThatArentPositive() throws {
        let trend = TrendSeries(values: try values([("2026-08-01", 80), ("2026-08-02", 0), ("2026-08-03", -1)]))
        #expect(trend.points.map(\.value) == [80])
    }

    @Test func constantWeightHasNoRateOfChange() {
        #expect(isClose(series(Array(repeating: 70, count: 10)).weeklyRate, 0))
    }

    @Test func linearLossConvergesToSevenTimesTheDailySlope() {
        let losing = series((0..<60).map { 80 - 0.1 * Double($0) })
        #expect(isClose(losing.weeklyRate, -0.7, tolerance: 0.01))
    }

    @Test func handlesGapsBetweenWeighIns() {
        // Every other day for 120 days, still −0.1 kg per day.
        let sparse = series((0..<60).map { 80 - 0.2 * Double($0) }, every: 2)
        #expect(isClose(sparse.weeklyRate, -0.7, tolerance: 0.02))
    }

    @Test func needsAWeekOfHistoryForARate() {
        #expect(series([80, 79.8, 79.9, 79.7, 79.6, 79.5, 79.4]).weeklyRate == nil) // 6-day span
        #expect(series([80, 79.8, 79.9, 79.7, 79.6, 79.5, 79.4, 79.3]).weeklyRate != nil) // 7-day span
        #expect(TrendSeries(values: [:]).weeklyRate == nil)
    }

    @Test func slicesTheLastDaysForTheSparkline() throws {
        let trend = series((0..<40).map { 80 - 0.05 * Double($0) })
        let recent = trend.points(endingOn: start.adding(days: 39), days: 28)
        #expect(recent.count == 28)
        #expect(recent.first?.day == start.adding(days: 12))
        // The trend still reflects the full history, not just the visible window.
        #expect(recent.first?.trend == trend.points[12].trend)
    }
}
