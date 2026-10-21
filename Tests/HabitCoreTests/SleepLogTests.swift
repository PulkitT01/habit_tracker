import Foundation
import Testing
@testable import HabitCore

@Suite struct SleepLogTests {
    @Test func formatsAndParsesTheDetailText() throws {
        let log = SleepLog(bedtime: TimeOfDay(hour: 23, minute: 30), wake: TimeOfDay(hour: 7, minute: 15))
        #expect(log.detail == "23:30-07:15")
        #expect(SleepLog(detail: "23:30-07:15") == log)
    }

    @Test(arguments: ["23:30", "23:30-", "-07:15", "25:00-07:00", "23:30–07:15", "23:30-07:15-08:00", ""])
    func rejectsMalformedDetailText(text: String) {
        #expect(SleepLog(detail: text) == nil)
    }

    @Test(arguments: [
        ("23:30", "07:15", 7.75),
        ("00:30", "07:00", 6.5), // bedtime after midnight
        ("22:00", "06:00", 8.0),
        ("23:10", "07:00", 7.83), // rounded to 2 decimal places
        ("07:00", "07:00", 0.0),
    ])
    func computesHoursSlept(bed: String, wake: String, hours: Double) throws {
        let log = SleepLog(bedtime: try #require(TimeOfDay(bed)), wake: try #require(TimeOfDay(wake)))
        #expect(try log.hours(wakeDay: day("2026-10-20"), timeZone: zone("Europe/Berlin")) == hours)
    }

    @Test func countsTheRealDurationOnDaylightSavingNights() throws {
        let log = SleepLog(bedtime: TimeOfDay(hour: 23, minute: 0), wake: TimeOfDay(hour: 7, minute: 0))
        let newYork = try zone("America/New_York")
        #expect(try log.hours(wakeDay: day("2026-11-01"), timeZone: newYork) == 9) // clocks fall back
        #expect(try log.hours(wakeDay: day("2026-03-08"), timeZone: newYork) == 7) // clocks spring forward
    }
}
