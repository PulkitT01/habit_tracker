import Foundation

extension Calendar {
    /// A Gregorian calendar in `timeZone`. Days are always Gregorian dates, whatever calendar the user prefers.
    static func gregorian(in timeZone: TimeZone) -> Calendar {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = timeZone
        return calendar
    }
}
