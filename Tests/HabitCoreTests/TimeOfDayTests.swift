import Foundation
import Testing
@testable import HabitCore

@Suite struct TimeOfDayTests {
    @Test(arguments: [("08:30", 8, 30), ("0:05", 0, 5), ("23:59", 23, 59), ("4:00", 4, 0)])
    func parsesValidText(text: String, hour: Int, minute: Int) throws {
        let time = try #require(TimeOfDay(text))
        #expect(time.hour == hour)
        #expect(time.minute == minute)
    }

    @Test(arguments: ["24:00", "12:60", "8:5", "830", "", "ab:cd", "-1:30", "08:30:00", " 08:30", "٠٨:٣٠"])
    func rejectsInvalidText(text: String) {
        #expect(TimeOfDay(text) == nil)
    }

    @Test func formatsWithZeroPadding() {
        #expect(TimeOfDay(hour: 7, minute: 5).description == "07:05")
        #expect(TimeOfDay(hour: 21, minute: 30).description == "21:30")
    }

    @Test func ordersByTimeOfDay() {
        #expect(TimeOfDay(hour: 8, minute: 30) < TimeOfDay(hour: 21, minute: 0))
        #expect(TimeOfDay(hour: 8, minute: 30).minutesSinceMidnight == 510)
    }

    @Test func roundTripsThroughJSONAsText() throws {
        let data = try JSONEncoder().encode([TimeOfDay(hour: 21, minute: 30)])
        #expect(String(decoding: data, as: UTF8.self) == #"["21:30"]"#)
        #expect(try JSONDecoder().decode([TimeOfDay].self, from: data) == [TimeOfDay(hour: 21, minute: 30)])
    }

    @Test func convertsToAndFromPickerDates() throws {
        let berlin = try zone("Europe/Berlin")
        let time = TimeOfDay(hour: 23, minute: 30)
        let date = try time.date(on: day("2026-10-20"), in: berlin)
        #expect(try date == instant("2026-10-20T21:30:00Z"))
        #expect(TimeOfDay(of: date, in: berlin) == time)
        #expect(try TimeOfDay(of: instant("2026-10-20T21:30:00Z"), in: zone("Asia/Kolkata")) == TimeOfDay(hour: 3, minute: 0))
    }
}
