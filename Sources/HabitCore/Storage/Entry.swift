import GRDB

/// One row of the `entries` table: a habit's value on a logical day.
/// A NULL `value` (or no row at all) means "not logged"; 0 means "logged, didn't do it".
public struct Entry: Hashable, Sendable, Codable, FetchableRecord, PersistableRecord {
    public static let databaseTableName = "entries"

    public let date: Day
    public let habitId: String
    public let value: Double?
    /// Tag choices ("india,here") or sleep times ("23:30-07:15").
    public let detail: String?
    /// ISO 8601 time of the last edit, with UTC offset.
    public let loggedAt: String
    /// How the value was written; see `EntrySource`.
    public let source: String

    public init(date: Day, habitId: String, value: Double?, detail: String? = nil, loggedAt: String, source: String) {
        self.date = date
        self.habitId = habitId
        self.value = value
        self.detail = detail
        self.loggedAt = loggedAt
        self.source = source
    }

    enum CodingKeys: String, CodingKey {
        case date
        case habitId = "habit_id"
        case value
        case detail
        case loggedAt = "logged_at"
        case source
    }

    public enum Columns {
        public static let date = Column(CodingKeys.date)
        public static let habitId = Column(CodingKeys.habitId)
        public static let value = Column(CodingKeys.value)
    }
}
