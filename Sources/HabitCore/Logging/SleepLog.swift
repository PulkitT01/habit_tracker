import Foundation

/// A night's bedtime and wake time. Stored on the day you wake up: `value` holds the hours
/// slept and `detail` holds `"HH:MM-HH:MM"`.
public struct SleepLog: Sendable, Equatable {
    public static let defaultBedtime = TimeOfDay(hour: 23, minute: 0)
    public static let defaultWake = TimeOfDay(hour: 7, minute: 0)

    public let bedtime: TimeOfDay
    public let wake: TimeOfDay

    public init(bedtime: TimeOfDay, wake: TimeOfDay) {
        self.bedtime = bedtime
        self.wake = wake
    }

    /// Parses `"23:30-07:15"`.
    public init?(detail: String) {
        let parts = detail.split(separator: "-", omittingEmptySubsequences: false)
        guard parts.count == 2, let bedtime = TimeOfDay(String(parts[0])), let wake = TimeOfDay(String(parts[1])) else {
            return nil
        }
        self.init(bedtime: bedtime, wake: wake)
    }

    public var detail: String { "\(bedtime)-\(wake)" }

    /// Real elapsed hours for the night ending on the morning of `wakeDay`, rounded to 2 decimals.
    /// A bedtime later than the wake time is on the evening before. DST nights are an hour shorter or longer.
    public func hours(wakeDay: Day, timeZone: TimeZone) -> Double {
        let bedDay = bedtime > wake ? wakeDay.adding(days: -1) : wakeDay
        let calendar = Calendar.gregorian(in: timeZone)
        guard let bedDate = calendar.date(from: components(of: bedDay, at: bedtime)),
              let wakeDate = calendar.date(from: components(of: wakeDay, at: wake))
        else {
            fatalError("Could not place \(detail) on \(wakeDay) in \(timeZone.identifier)")
        }
        let hours = wakeDate.timeIntervalSince(bedDate) / 3600
        return (hours * 100).rounded() / 100
    }

    private func components(of day: Day, at time: TimeOfDay) -> DateComponents {
        DateComponents(year: day.year, month: day.month, day: day.day, hour: time.hour, minute: time.minute)
    }
}
