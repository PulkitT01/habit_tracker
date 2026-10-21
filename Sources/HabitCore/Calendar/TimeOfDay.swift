import Foundation

/// A wall-clock time without a date, such as a reminder time or a bedtime.
/// Its text form is 24-hour `HH:MM` (parsing also accepts a single-digit hour).
public struct TimeOfDay: Hashable, Comparable, Sendable, CustomStringConvertible {
    public let hour: Int
    public let minute: Int

    public init(hour: Int, minute: Int) {
        precondition((0..<24).contains(hour) && (0..<60).contains(minute), "Invalid time \(hour):\(minute)")
        self.hour = hour
        self.minute = minute
    }

    public init?(_ text: String) {
        let parts = text.split(separator: ":", omittingEmptySubsequences: false)
        guard parts.count == 2,
              (1...2).contains(parts[0].count), parts[1].count == 2,
              parts.allSatisfy({ $0.allSatisfy { $0.isASCII && $0.isNumber } }),
              let hour = Int(parts[0]), let minute = Int(parts[1]),
              (0..<24).contains(hour), (0..<60).contains(minute)
        else { return nil }
        self.init(hour: hour, minute: minute)
    }

    public var minutesSinceMidnight: Int { hour * 60 + minute }

    public var description: String { "\(zeroPadded(hour, width: 2)):\(zeroPadded(minute, width: 2))" }

    public static func < (lhs: TimeOfDay, rhs: TimeOfDay) -> Bool {
        lhs.minutesSinceMidnight < rhs.minutesSinceMidnight
    }
}

extension TimeOfDay: Codable {
    public init(from decoder: any Decoder) throws {
        let container = try decoder.singleValueContainer()
        let text = try container.decode(String.self)
        guard let time = TimeOfDay(text) else {
            throw DecodingError.dataCorruptedError(in: container, debugDescription: "Expected HH:MM, got \"\(text)\"")
        }
        self = time
    }

    public func encode(to encoder: any Encoder) throws {
        var container = encoder.singleValueContainer()
        try container.encode(description)
    }
}

extension TimeOfDay {
    /// The wall-clock time of `date` in `timeZone`, ignoring seconds.
    public init(of date: Date, in timeZone: TimeZone) {
        let parts = Calendar.gregorian(in: timeZone).dateComponents([.hour, .minute], from: date)
        self.init(hour: parts.hour ?? 0, minute: parts.minute ?? 0)
    }

    /// This time on calendar date `day` in `timeZone`, for binding to a time-only date picker.
    public func date(on day: Day, in timeZone: TimeZone) -> Date {
        let components = DateComponents(year: day.year, month: day.month, day: day.day, hour: hour, minute: minute)
        guard let date = Calendar.gregorian(in: timeZone).date(from: components) else {
            fatalError("Could not place \(self) on \(day) in \(timeZone.identifier)")
        }
        return date
    }
}
