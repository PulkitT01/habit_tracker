import Foundation

/// Writes the database as CSV: `entries.csv` in the same long format as the table (one row per
/// habit per day, every row including NULL values) and `day_notes.csv`.
public enum Exporter {
    public static let entriesFileName = "entries.csv"
    public static let notesFileName = "day_notes.csv"

    public static func entriesCSV(_ entries: [Entry]) -> String {
        CSVWriter.document(
            header: ["date", "habit_id", "value", "detail", "logged_at", "source"],
            rows: entries.map { entry in
                [entry.date.iso, entry.habitId, entry.value.map { "\($0)" }, entry.detail, entry.loggedAt, entry.source]
            }
        )
    }

    public static func notesCSV(_ notes: [DayNote]) -> String {
        CSVWriter.document(header: ["date", "note"], rows: notes.map { [$0.date.iso, $0.note] })
    }

    /// Writes both files into `folder`, replacing earlier exports with the same names.
    public static func export(from repository: EntryRepository, to folder: URL) throws -> ExportSummary {
        let entries = try repository.allEntries()
        let notes = try repository.allNotes()
        try entriesCSV(entries).write(to: folder.appending(path: entriesFileName), atomically: true, encoding: .utf8)
        try notesCSV(notes).write(to: folder.appending(path: notesFileName), atomically: true, encoding: .utf8)
        return ExportSummary(entryCount: entries.count, noteCount: notes.count, folder: folder)
    }
}
