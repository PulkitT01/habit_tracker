import Testing
@testable import HabitCore

@Suite struct StatsSnapshotTests {
    private func entry(_ dayText: String, _ habitId: String, _ value: Double?) throws -> Entry {
        try Entry(date: day(dayText), habitId: habitId, value: value, loggedAt: "2026-10-20T21:00:00Z", source: EntrySource.manual)
    }

    @Test func buildsRatesAndDotsPerHabitInOrder() throws {
        let read = try habit("read")
        let pushups = try habit("pushups", .count, minTarget: 5)
        let recent = try [
            entry("2026-10-20", "read", 1),
            entry("2026-10-19", "read", 0),
            entry("2026-10-20", "pushups", 3),
            entry("2026-10-18", "pushups", nil), // NULL rows never count as logged
        ]
        let snapshot = try StatsSnapshot(habits: [read, pushups], today: day("2026-10-20"), recentEntries: recent, trendHistories: [:])

        #expect(snapshot.rates.map(\.habit.id) == ["read", "pushups"])
        let readRates = try #require(snapshot.rates.first)
        #expect(readRates.dots.count == 7)
        #expect(readRates.dots.last?.state == .done)
        #expect(readRates.week == CompletionRate(done: 1, missed: 1, notLogged: 5))
        #expect(readRates.month.eligible == 20) // active since Oct 1
        let pushupDots = try #require(snapshot.rates.last).dots.map(\.state)
        #expect(pushupDots.suffix(3) == [.notLogged, .notLogged, .missed])
        #expect(snapshot.trends.isEmpty)
    }

    @Test func buildsTrendsFromTheFullHistory() throws {
        let weight = try Habit(id: "weight", name: "Weight", type: .number, unit: "kg", decimals: 1, showsTrend: true,
                               prompt: .morning, order: 10, activeFrom: day("2026-01-01"))
        let history = try [entry("2026-01-01", "weight", 80), entry("2026-10-20", "weight", 70)]
        let snapshot = try StatsSnapshot(habits: [weight], today: day("2026-10-20"), recentEntries: [], trendHistories: ["weight": history])

        let trend = try #require(snapshot.trends.first)
        #expect(trend.habit.id == "weight")
        #expect(trend.series.points.map(\.value) == [80, 70])
        #expect(trend.series.latest?.trend == 79)
    }
}
