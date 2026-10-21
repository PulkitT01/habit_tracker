import Foundation
import GRDB

/// Reads and writes entries and day notes. Queries named "logged" skip NULL values,
/// so a NULL row is treated exactly like a missing one.
public struct EntryRepository: Sendable {
    let database: AppDatabase

    public init(_ database: AppDatabase) {
        self.database = database
    }

    // MARK: - Entries

    public func loggedEntries(on day: Day) throws -> [Entry] {
        try database.writer.read { db in
            try Entry.filter(Entry.Columns.date == day && Entry.Columns.value != nil)
                .order(Entry.Columns.habitId)
                .fetchAll(db)
        }
    }

    /// Logged entries from `start` through `end`, inclusive, sorted by date then habit.
    public func loggedEntries(from start: Day, through end: Day) throws -> [Entry] {
        try database.writer.read { db in
            try Entry.filter(Entry.Columns.date >= start && Entry.Columns.date <= end && Entry.Columns.value != nil)
                .order(Entry.Columns.date, Entry.Columns.habitId)
                .fetchAll(db)
        }
    }

    /// A habit's full logged history, oldest first.
    public func loggedEntries(habitId: String) throws -> [Entry] {
        try database.writer.read { db in
            try Entry.filter(Entry.Columns.habitId == habitId && Entry.Columns.value != nil)
                .order(Entry.Columns.date)
                .fetchAll(db)
        }
    }

    /// The most recent logged entry strictly before `day`, used for placeholders and suggestions.
    public func latestLoggedEntry(habitId: String, before day: Day) throws -> Entry? {
        try database.writer.read { db in
            try Entry.filter(Entry.Columns.habitId == habitId && Entry.Columns.date < day && Entry.Columns.value != nil)
                .order(Entry.Columns.date.desc)
                .fetchOne(db)
        }
    }

    /// The first day with any row, or nil for an empty database.
    public func earliestDay() throws -> Day? {
        try database.writer.read { db in
            try Day.fetchOne(db, sql: "SELECT MIN(date) FROM entries")
        }
    }

    /// Inserts the entry, or replaces the value, detail, timestamp and source of an existing one.
    public func save(_ entry: Entry) throws {
        try database.writer.write { db in
            try entry.upsert(db)
        }
    }

    /// Removes an entry, returning the habit to "not logged" for that day.
    public func deleteEntry(on day: Day, habitId: String) throws {
        _ = try database.writer.write { db in
            try Entry.deleteOne(db, key: ["date": day, "habit_id": habitId])
        }
    }

    /// Writes 0 for each habit that isn't logged on `day` (no row, or a NULL value).
    /// Never touches a logged value. Returns how many entries were filled.
    @discardableResult
    public func fillZeros(on day: Day, habitIds: [String], loggedAt: String) throws -> Int {
        try database.writer.write { db in
            var filled = 0
            for habitId in habitIds {
                try db.execute(
                    sql: """
                        INSERT INTO entries (date, habit_id, value, detail, logged_at, source)
                        VALUES (?, ?, 0, NULL, ?, ?)
                        ON CONFLICT (date, habit_id) DO UPDATE SET
                            value = excluded.value,
                            detail = excluded.detail,
                            logged_at = excluded.logged_at,
                            source = excluded.source
                        WHERE entries.value IS NULL
                        """,
                    arguments: [day, habitId, loggedAt, EntrySource.autoZero]
                )
                filled += db.changesCount
            }
            return filled
        }
    }

    /// Every row as stored (including NULL values), sorted by date then habit, for export.
    public func allEntries() throws -> [Entry] {
        try database.writer.read { db in
            try Entry.order(Entry.Columns.date, Entry.Columns.habitId).fetchAll(db)
        }
    }

    // MARK: - Day notes

    public func note(on day: Day) throws -> String? {
        try database.writer.read { db in
            try DayNote.fetchOne(db, key: day)?.note
        }
    }

    /// Saves the note trimmed of surrounding whitespace; a blank note deletes the row.
    public func setNote(_ text: String, on day: Day) throws {
        let note = text.trimmingCharacters(in: .whitespacesAndNewlines)
        try database.writer.write { db in
            if note.isEmpty {
                _ = try DayNote.deleteOne(db, key: day)
            } else {
                try DayNote(date: day, note: note).upsert(db)
            }
        }
    }

    public func allNotes() throws -> [DayNote] {
        try database.writer.read { db in
            try DayNote.order(Column("date")).fetchAll(db)
        }
    }
}
