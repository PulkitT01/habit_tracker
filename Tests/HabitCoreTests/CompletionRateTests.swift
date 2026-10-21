import Testing
@testable import HabitCore

@Suite struct CompletionRateTests {
    private let today: Day

    init() throws {
        today = try day("2026-10-20")
    }

    /// Values for `offsets` days before today (0 = today).
    private func logged(_ entries: [(offset: Int, value: Double)]) -> [Day: Double] {
        Dictionary(uniqueKeysWithValues: entries.map { (today.adding(days: -$0.offset), $0.value) })
    }

    @Test func isOneWhenEveryDayIsDone() throws {
        let rate = CompletionRate(habit: try habit("read"), values: logged((0..<7).map { ($0, 1) }), today: today, days: 7)
        #expect(rate == CompletionRate(done: 7, missed: 0, notLogged: 0))
        #expect(rate.fraction == 1)
    }

    @Test func countsUnloggedPastDaysAsNotDone() throws {
        let values = logged([(0, 1), (1, 1), (2, 0), (4, 1)]) // offsets 3, 5, 6 not logged
        let rate = CompletionRate(habit: try habit("read"), values: values, today: today, days: 7)
        #expect(rate == CompletionRate(done: 3, missed: 1, notLogged: 3))
        #expect(rate.eligible == 7)
        #expect(rate.fraction == 3.0 / 7.0)
    }

    @Test func excludesDaysBeforeActiveFrom() throws {
        // Started 3 days ago: only today and the two days before are eligible, even over 28 days.
        let started = try habit("read", from: "2026-10-18")
        let values = logged([(0, 1), (1, 1), (2, 1)])
        #expect(CompletionRate(habit: started, values: values, today: today, days: 7) == CompletionRate(done: 3, missed: 0, notLogged: 0))
        #expect(CompletionRate(habit: started, values: values, today: today, days: 28).fraction == 1)
    }

    @Test func excludesDaysAfterActiveTo() throws {
        let retired = try habit("read", from: "2026-10-01", to: "2026-10-15")
        let values = logged([(5, 1), (6, 0)]) // Oct 15 done, Oct 14 missed
        // Window ends yesterday (today isn't logged): Oct 13...Oct 19, of which Oct 13–15 are active.
        #expect(CompletionRate(habit: retired, values: values, today: today, days: 7) == CompletionRate(done: 1, missed: 1, notLogged: 1))
    }

    @Test func windowEndsYesterdayWhileTodayIsUnlogged() throws {
        // Yesterday back to 7 days ago all done, today not logged yet: no morning dip.
        let values = logged((1...7).map { ($0, 1) })
        let rate = CompletionRate(habit: try habit("read"), values: values, today: today, days: 7)
        #expect(rate == CompletionRate(done: 7, missed: 0, notLogged: 0))
    }

    @Test func windowEndsTodayOnceTodayIsLogged() throws {
        // Logging today (missed) moves the window: 7 days ago drops out.
        let values = logged([(0, 0)] + (1...7).map { ($0, 1) })
        let rate = CompletionRate(habit: try habit("read"), values: values, today: today, days: 7)
        #expect(rate == CompletionRate(done: 6, missed: 1, notLogged: 0))
    }

    @Test func appliesTheMinimumTarget() throws {
        let pushups = try habit("pushups", .count, minTarget: 5)
        let values = logged([(0, 4), (1, 5), (2, 12), (3, 0)])
        #expect(CompletionRate(habit: pushups, values: values, today: today, days: 4) == CompletionRate(done: 2, missed: 2, notLogged: 0))
    }

    @Test func treatsAnyPositiveValueAsDoneWithoutATarget() throws {
        let negatives = try habit("negatives", .count)
        let values = logged([(0, 1), (1, 0)])
        #expect(CompletionRate(habit: negatives, values: values, today: today, days: 2) == CompletionRate(done: 1, missed: 1, notLogged: 0))
    }

    @Test func hasNoFractionWithoutEligibleDays() throws {
        let startsToday = try habit("read", from: "2026-10-20")
        let rate = CompletionRate(habit: startsToday, values: [:], today: today, days: 7)
        #expect(rate.eligible == 0)
        #expect(rate.fraction == nil)
    }

    @Test func treatsNullRowsAsNotLogged() throws {
        let repository = EntryRepository(try AppDatabase.inMemory())
        try repository.database.writer.write { db in
            try db.execute(sql: """
                INSERT INTO entries (date, habit_id, value, logged_at, source) VALUES
                ('2026-10-20', 'read', 1, '2026-10-20T21:00:00Z', 'manual'),
                ('2026-10-19', 'read', NULL, '2026-10-19T21:00:00Z', 'import'),
                ('2026-10-18', 'read', 0, '2026-10-18T21:00:00Z', 'manual')
                """)
        }
        let values = Dictionary(uniqueKeysWithValues: try repository.loggedEntries(habitId: "read").compactMap { entry in
            entry.value.map { (entry.date, $0) }
        })
        let rate = CompletionRate(habit: try habit("read", from: "2026-10-18"), values: values, today: today, days: 7)
        #expect(rate == CompletionRate(done: 1, missed: 1, notLogged: 1))
    }

    @Test func dotsDistinguishEveryState() throws {
        let pushups = try habit("pushups", .count, minTarget: 5, from: "2026-10-15")
        let values = logged([(0, 10), (1, 3), (3, 5)])
        let dots = DayDot.week(for: pushups, values: values, endingOn: today)

        #expect(dots.map(\.day) == (0..<7).reversed().map { today.adding(days: -$0) })
        #expect(dots.map(\.state) == [.inactive, .notLogged, .notLogged, .done, .notLogged, .missed, .done])
    }
}
