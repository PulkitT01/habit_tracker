import Foundation

/// A calendar date with no time or time zone, stored as `YYYY-MM-DD`.
/// Use `DayBoundary` to find the logical day (which ends at 04:00) for a moment in time.
public struct Day: Hashable, Comparable, Sendable, CustomStringConvertible {
    public let year: Int
    public let month: Int
    public let day: Int

    /// Day arithmetic runs in UTC so it is never affected by daylight saving transitions.
    private static let arithmetic = Calendar.gregorian(in: .gmt)

    public init?(year: Int, month: Int, day: Int) {
        guard (1000...9999).contains(year),
              let date = Self.arithmetic.date(from: DateComponents(year: year, month: month, day: day))
        else { return nil }
        // DateComponents roll over (Feb 30 → Mar 2), so make sure the date survived unchanged.
        let parts = Self.arithmetic.dateComponents([.year, .month, .day], from: date)
        guard parts.year == year, parts.month == month, parts.day == day else { return nil }
        self.init(unchecked: year, month, day)
    }

    /// Parses exactly `YYYY-MM-DD`.
    public init?(_ iso: String) {
        let parts = iso.split(separator: "-", omittingEmptySubsequences: false)
        guard parts.count == 3,
              parts[0].count == 4, parts[1].count == 2, parts[2].count == 2,
              parts.allSatisfy({ $0.allSatisfy { $0.isASCII && $0.isNumber } }),
              let year = Int(parts[0]), let month = Int(parts[1]), let day = Int(parts[2])
        else { return nil }
        self.init(year: year, month: month, day: day)
    }

    /// The calendar date of `date` as seen on a wall clock in `timeZone` (no 04:00 shift).
    public init(calendarDateOf date: Date, in timeZone: TimeZone) {
        let parts = Calendar.gregorian(in: timeZone).dateComponents([.year, .month, .day], from: date)
        guard let year = parts.year, let month = parts.month, let day = parts.day else {
            fatalError("Gregorian calendar returned no date components for \(date)")
        }
        self.init(unchecked: year, month, day)
    }

    private init(unchecked year: Int, _ month: Int, _ day: Int) {
        self.year = year
        self.month = month
        self.day = day
    }

    public var iso: String {
        "\(zeroPadded(year, width: 4))-\(zeroPadded(month, width: 2))-\(zeroPadded(day, width: 2))"
    }

    public var description: String { iso }

    public func adding(days: Int) -> Day {
        guard let moved = Self.arithmetic.date(byAdding: .day, value: days, to: utcMidnight) else {
            fatalError("Could not add \(days) days to \(iso)")
        }
        return Day(calendarDateOf: moved, in: .gmt)
    }

    /// Number of days from this day to `other`; negative when `other` is earlier.
    public func days(until other: Day) -> Int {
        Self.arithmetic.dateComponents([.day], from: utcMidnight, to: other.utcMidnight).day ?? 0
    }

    /// Noon on this date in `timeZone`: a stable anchor for date pickers that avoids DST edges.
    public func noon(in timeZone: TimeZone) -> Date {
        let components = DateComponents(year: year, month: month, day: day, hour: 12)
        guard let date = Calendar.gregorian(in: timeZone).date(from: components) else {
            fatalError("Could not build noon of \(iso) in \(timeZone.identifier)")
        }
        return date
    }

    public static func < (lhs: Day, rhs: Day) -> Bool {
        (lhs.year, lhs.month, lhs.day) < (rhs.year, rhs.month, rhs.day)
    }

    private var utcMidnight: Date {
        guard let date = Self.arithmetic.date(from: DateComponents(year: year, month: month, day: day)) else {
            fatalError("Invalid day \(iso)")
        }
        return date
    }
}

extension Day: Codable {
    public init(from decoder: any Decoder) throws {
        let container = try decoder.singleValueContainer()
        let text = try container.decode(String.self)
        guard let day = Day(text) else {
            throw DecodingError.dataCorruptedError(in: container, debugDescription: "Expected YYYY-MM-DD, got \"\(text)\"")
        }
        self = day
    }

    public func encode(to encoder: any Encoder) throws {
        var container = encoder.singleValueContainer()
        try container.encode(iso)
    }
}
