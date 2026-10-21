import Foundation

/// Maps moments in time to logical days. A day ends at 04:00 local time, so logging at
/// 01:00 counts toward the previous day. Works on wall-clock hours, so DST shifts are harmless.
public struct DayBoundary: Sendable {
    public static let startHour = 4

    public let timeZone: TimeZone
    private let calendar: Calendar

    public init(timeZone: TimeZone) {
        self.timeZone = timeZone
        self.calendar = .gregorian(in: timeZone)
    }

    /// The logical day that `date` falls in.
    public func day(containing date: Date) -> Day {
        let calendarDay = Day(calendarDateOf: date, in: timeZone)
        return calendar.component(.hour, from: date) < Self.startHour ? calendarDay.adding(days: -1) : calendarDay
    }

    /// The moment `time` occurs during logical `day`. Times before 04:00 fall after midnight,
    /// on the next calendar date (01:00 of Oct 20 is Oct 21, 01:00).
    public func date(for day: Day, at time: TimeOfDay) -> Date {
        let calendarDay = time.hour < Self.startHour ? day.adding(days: 1) : day
        let components = DateComponents(
            year: calendarDay.year, month: calendarDay.month, day: calendarDay.day,
            hour: time.hour, minute: time.minute
        )
        guard let date = calendar.date(from: components) else {
            fatalError("Could not place \(time) on \(day) in \(timeZone.identifier)")
        }
        return date
    }

    /// When the logical day after the one containing `date` begins.
    public func nextStart(after date: Date) -> Date {
        self.date(for: day(containing: date).adding(days: 1), at: TimeOfDay(hour: Self.startHour, minute: 0))
    }
}
