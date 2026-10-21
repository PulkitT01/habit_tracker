import GRDB

/// One row of `day_notes`: an optional free-text note for a logical day ("sick", "travelling").
public struct DayNote: Hashable, Sendable, Codable, FetchableRecord, PersistableRecord {
    public static let databaseTableName = "day_notes"

    public let date: Day
    public let note: String

    public init(date: Day, note: String) {
        self.date = date
        self.note = note
    }
}
