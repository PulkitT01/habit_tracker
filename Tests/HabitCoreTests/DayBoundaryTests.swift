import Foundation
import Testing
@testable import HabitCore

@Suite struct DayBoundaryTests {
    // Berlin is UTC+2 (CEST) until 2026-10-25 and UTC+1 (CET) after.
    @Test(arguments: [
        ("2026-10-21T01:59:00Z", "2026-10-20"), // 03:59 local → still the previous day
        ("2026-10-21T02:00:00Z", "2026-10-21"), // 04:00 local → new day
        ("2026-10-20T22:30:00Z", "2026-10-20"), // 00:30 local → previous day
        ("2026-10-21T21:59:00Z", "2026-10-21"), // 23:59 local
        ("2026-10-31T23:00:00Z", "2026-10-31"), // 00:00 on Nov 1 (CET) → Oct 31
        ("2027-01-01T01:00:00Z", "2026-12-31"), // 02:00 on New Year's Day → Dec 31
    ])
    func assignsTimesBeforeFourToThePreviousDay(moment: String, expected: String) throws {
        let boundary = DayBoundary(timeZone: try zone("Europe/Berlin"))
        #expect(try boundary.day(containing: instant(moment)) == day(expected))
    }

    // New York falls back from 02:00 EDT to 01:00 EST on 2026-11-01, so 01:30 happens twice.
    @Test(arguments: [
        ("2026-11-01T05:30:00Z", "2026-10-31"), // 01:30 EDT
        ("2026-11-01T06:30:00Z", "2026-10-31"), // 01:30 EST
        ("2026-11-01T08:59:00Z", "2026-10-31"), // 03:59 EST
        ("2026-11-01T09:00:00Z", "2026-11-01"), // 04:00 EST
    ])
    func handlesTheFallBackTransition(moment: String, expected: String) throws {
        let boundary = DayBoundary(timeZone: try zone("America/New_York"))
        #expect(try boundary.day(containing: instant(moment)) == day(expected))
    }

    // New York springs forward from 02:00 EST to 03:00 EDT on 2026-03-08.
    @Test(arguments: [
        ("2026-03-08T06:59:00Z", "2026-03-07"), // 01:59 EST
        ("2026-03-08T07:30:00Z", "2026-03-07"), // 03:30 EDT
        ("2026-03-08T08:00:00Z", "2026-03-08"), // 04:00 EDT
    ])
    func handlesTheSpringForwardTransition(moment: String, expected: String) throws {
        let boundary = DayBoundary(timeZone: try zone("America/New_York"))
        #expect(try boundary.day(containing: instant(moment)) == day(expected))
    }

    @Test func placesTimesOnTheLogicalDay() throws {
        let boundary = DayBoundary(timeZone: try zone("Europe/Berlin"))
        let logicalDay = try day("2026-10-20")
        #expect(try boundary.date(for: logicalDay, at: TimeOfDay(hour: 21, minute: 30)) == instant("2026-10-20T19:30:00Z"))
        #expect(try boundary.date(for: logicalDay, at: TimeOfDay(hour: 8, minute: 30)) == instant("2026-10-20T06:30:00Z"))
        // 01:00 belongs to the night after Oct 20, i.e. Oct 21 on the wall clock.
        #expect(try boundary.date(for: logicalDay, at: TimeOfDay(hour: 1, minute: 0)) == instant("2026-10-20T23:00:00Z"))
    }

    @Test func findsTheNextDayStart() throws {
        let boundary = DayBoundary(timeZone: try zone("Europe/Berlin"))
        let nextStart = try instant("2026-10-21T02:00:00Z") // Oct 21 04:00 CEST
        #expect(try boundary.nextStart(after: instant("2026-10-20T20:00:00Z")) == nextStart) // 22:00
        #expect(try boundary.nextStart(after: instant("2026-10-21T00:00:00Z")) == nextStart) // 02:00
        #expect(try boundary.nextStart(after: nextStart) == instant("2026-10-22T02:00:00Z"))
    }
}
