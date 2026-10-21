import Foundation
import Testing
@testable import HabitCore

@Suite struct DayTests {
    @Test func parsesAndFormatsISODates() throws {
        let parsed = try day("2026-03-07")
        #expect(parsed.year == 2026)
        #expect(parsed.month == 3)
        #expect(parsed.day == 7)
        #expect(parsed.iso == "2026-03-07")
        #expect(parsed.description == "2026-03-07")
    }

    @Test(arguments: [
        "2026-02-30", "2026-13-01", "2026-00-10", "26-10-20", "2026-1-05", "2026/10/20",
        "", "2026-10-20T00:00", "2026-10-2a", "0999-01-01",
    ])
    func rejectsInvalidDates(text: String) {
        #expect(Day(text) == nil)
    }

    @Test func acceptsLeapDayOnlyInLeapYears() {
        #expect(Day("2028-02-29") != nil)
        #expect(Day("2026-02-29") == nil)
    }

    @Test(arguments: [
        ("2026-02-28", 1, "2026-03-01"),
        ("2028-02-28", 1, "2028-02-29"),
        ("2026-12-31", 1, "2027-01-01"),
        ("2026-03-01", -1, "2026-02-28"),
        ("2026-10-20", -28, "2026-09-22"),
    ])
    func addsDaysAcrossMonthsAndYears(start: String, offset: Int, expected: String) throws {
        #expect(try day(start).adding(days: offset) == day(expected))
    }

    @Test func countsDaysBetweenDates() throws {
        #expect(try day("2026-10-20").days(until: day("2026-11-02")) == 13)
        #expect(try day("2026-11-02").days(until: day("2026-10-20")) == -13)
        #expect(try day("2028-02-01").days(until: day("2028-03-01")) == 29)
    }

    @Test func ordersChronologically() throws {
        #expect(try day("2026-09-30") < day("2026-10-01"))
        #expect(try day("2025-12-31") < day("2026-01-01"))
    }

    @Test func roundTripsThroughJSONAsText() throws {
        let original = try day("2026-10-20")
        let data = try JSONEncoder().encode([original])
        #expect(String(decoding: data, as: UTF8.self) == #"["2026-10-20"]"#)
        #expect(try JSONDecoder().decode([Day].self, from: data) == [original])
    }

    @Test func convertsToAndFromLocalNoon() throws {
        let tokyo = try zone("Asia/Tokyo")
        let original = try day("2026-10-20")
        let noon = original.noon(in: tokyo)
        #expect(try noon == instant("2026-10-20T03:00:00Z"))
        #expect(Day(calendarDateOf: noon, in: tokyo) == original)
        // West of UTC the same instant can be a different calendar date.
        let losAngeles = try zone("America/Los_Angeles")
        #expect(try Day(calendarDateOf: instant("2026-10-20T03:00:00Z"), in: losAngeles) == day("2026-10-19"))
    }
}
