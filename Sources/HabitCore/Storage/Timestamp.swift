import Foundation

/// Formats `logged_at`: ISO 8601 in local time with a colon-separated offset,
/// e.g. `2026-10-20T21:45:12+02:00`. pandas parses it with `pd.to_datetime(..., utc=True)`.
public enum Timestamp {
    public static func string(from date: Date, timeZone: TimeZone) -> String {
        date.formatted(Date.ISO8601FormatStyle(timeZoneSeparator: .colon, timeZone: timeZone))
    }
}
