import Foundation
import GRDB
import Testing
@testable import HabitCore

@Suite struct EntryRepositoryTests {
    private let database: AppDatabase
    private let repository: EntryRepository

    init() throws {
        database = try AppDatabase.inMemory()
        repository = EntryRepository(database)
    }

    private func entry(
        _ dayText: String, _ habitId: String, _ value: Double?,
        detail: String? = nil, loggedAt: String = "2026-10-20T21:00:00+02:00", source: String = EntrySource.manual
    ) throws -> Entry {
        try Entry(date: day(dayText), habitId: habitId, value: value, detail: detail, loggedAt: loggedAt, source: source)
    }

    private func rowCount() throws -> Int {
        try database.writer.read { db in try Int.fetchOne(db, sql: "SELECT COUNT(*) FROM entries") ?? 0 }
    }

    /// Simulates another client (or a hand edit) writing an explicit NULL value.
    private func insertNullRow(_ dayText: String, _ habitId: String) throws {
        try database.writer.write { db in
            try db.execute(
                sql: "INSERT INTO entries (date, habit_id, value, logged_at, source) VALUES (?, ?, NULL, ?, 'import')",
                arguments: [dayText, habitId, "2026-10-20T08:00:00Z"]
            )
        }
    }

    @Test func savesAndReadsAnEntry() throws {
        let saved = try entry("2026-10-20", "read", 1)
        try repository.save(saved)
        #expect(try repository.loggedEntries(on: day("2026-10-20")) == [saved])
    }

    @Test func upsertKeepsOneRowAndUpdatesValueAndTimestamp() throws {
        try repository.save(entry("2026-10-20", "pushups", 0, loggedAt: "2026-10-20T21:00:00+02:00", source: EntrySource.autoZero))
        try repository.save(entry("2026-10-20", "pushups", 20, loggedAt: "2026-10-20T22:15:00+02:00"))

        #expect(try rowCount() == 1)
        let stored = try #require(repository.loggedEntries(on: day("2026-10-20")).first)
        #expect(stored.value == 20)
        #expect(stored.loggedAt == "2026-10-20T22:15:00+02:00")
        #expect(stored.source == EntrySource.manual)
    }

    @Test func zeroIsALoggedValueDistinctFromNotLogged() throws {
        try repository.save(entry("2026-10-20", "study", 0))

        let stored = try #require(repository.loggedEntries(on: day("2026-10-20")).first)
        #expect(stored.value == 0)
        #expect(stored.value != nil)
        #expect(try repository.loggedEntries(on: day("2026-10-21")).isEmpty)
    }

    @Test func clearingAnEntryDeletesTheRow() throws {
        try repository.save(entry("2026-10-20", "study", 1))
        try repository.deleteEntry(on: day("2026-10-20"), habitId: "study")

        #expect(try rowCount() == 0)
        #expect(try repository.loggedEntries(on: day("2026-10-20")).isEmpty)
    }

    @Test func nullRowsReadAsNotLoggedButAreExported() throws {
        try insertNullRow("2026-10-20", "weight")

        #expect(try repository.loggedEntries(on: day("2026-10-20")).isEmpty)
        #expect(try repository.loggedEntries(habitId: "weight").isEmpty)
        let exported = try repository.allEntries()
        #expect(exported.count == 1)
        #expect(exported.first?.value == nil)
    }

    @Test func fillingZerosNeverOverwritesALoggedValue() throws {
        try repository.save(entry("2026-10-20", "done", 1))
        try repository.save(entry("2026-10-20", "explicit_zero", 0, loggedAt: "2026-10-20T08:00:00+02:00"))
        try repository.save(entry("2026-10-20", "counted", 7))
        try insertNullRow("2026-10-20", "null_row")

        let filled = try repository.fillZeros(
            on: day("2026-10-20"),
            habitIds: ["done", "explicit_zero", "counted", "null_row", "missing"],
            loggedAt: "2026-10-20T22:00:00+02:00"
        )

        #expect(filled == 2)
        let values = try Dictionary(uniqueKeysWithValues: repository.allEntries().map { ($0.habitId, $0) })
        #expect(values["done"]?.value == 1)
        #expect(values["counted"]?.value == 7)
        #expect(values["explicit_zero"]?.loggedAt == "2026-10-20T08:00:00+02:00")
        #expect(values["explicit_zero"]?.source == EntrySource.manual)
        for id in ["null_row", "missing"] {
            #expect(values[id]?.value == 0)
            #expect(values[id]?.source == EntrySource.autoZero)
            #expect(values[id]?.loggedAt == "2026-10-20T22:00:00+02:00")
        }
    }

    @Test func fetchesLoggedEntriesInAnInclusiveDateRange() throws {
        for dayText in ["2026-10-17", "2026-10-18", "2026-10-19", "2026-10-20"] {
            try repository.save(entry(dayText, "read", 1))
        }
        let range = try repository.loggedEntries(from: day("2026-10-18"), through: day("2026-10-19"))
        #expect(range.map(\.date.iso) == ["2026-10-18", "2026-10-19"])
    }

    @Test func findsTheLatestLoggedEntryBeforeADay() throws {
        try repository.save(entry("2026-10-17", "weight", 72.4))
        try repository.save(entry("2026-10-18", "weight", 72.1))
        try insertNullRow("2026-10-19", "weight")
        try repository.save(entry("2026-10-20", "weight", 71.9))

        let latest = try repository.latestLoggedEntry(habitId: "weight", before: day("2026-10-20"))
        #expect(latest?.value == 72.1)
        #expect(try repository.latestLoggedEntry(habitId: "weight", before: day("2026-10-17")) == nil)
    }

    @Test func listsAHabitsHistoryInDateOrder() throws {
        try repository.save(entry("2026-10-19", "weight", 72.1))
        try repository.save(entry("2026-10-17", "weight", 72.4))
        try repository.save(entry("2026-10-18", "read", 1))
        #expect(try repository.loggedEntries(habitId: "weight").map(\.value) == [72.4, 72.1])
    }

    @Test func findsTheEarliestDay() throws {
        #expect(try repository.earliestDay() == nil)
        try repository.save(entry("2026-10-19", "read", 1))
        try repository.save(entry("2026-10-12", "read", 0))
        #expect(try repository.earliestDay() == day("2026-10-12"))
    }

    @Test func savesUpdatesAndDeletesDayNotes() throws {
        let today = try day("2026-10-20")
        #expect(try repository.note(on: today) == nil)

        try repository.setNote("sick", on: today)
        try repository.setNote("  travelling \n", on: today)
        #expect(try repository.note(on: today) == "travelling")

        try repository.setNote("   ", on: today)
        #expect(try repository.note(on: today) == nil)
        #expect(try repository.allNotes().isEmpty)
    }

    @Test func storesPlainTextAndRealColumns() throws {
        try repository.save(entry("2026-10-20", "weight", 72.4, detail: nil))
        try repository.save(entry("2026-10-20", "sleep", 7.75, detail: "23:30-07:15"))
        let rows = try database.writer.read { db in
            try Row.fetchAll(db, sql: "SELECT typeof(date) AS dateType, date, typeof(value) AS valueType, detail FROM entries ORDER BY habit_id")
        }
        #expect(rows.map { $0["dateType"] as String } == ["text", "text"])
        #expect(rows.map { $0["date"] as String } == ["2026-10-20", "2026-10-20"])
        #expect(rows.map { $0["valueType"] as String } == ["real", "real"])
        #expect(rows.map { $0["detail"] as String? } == ["23:30-07:15", nil])
    }

    @Test func schemaHasTheDocumentedColumns() throws {
        let columns = try database.writer.read { db in
            try Row.fetchAll(db, sql: "PRAGMA table_info(entries)").map { row in
                "\(row["name"] as String) \(row["type"] as String) notnull=\(row["notnull"] as Int) pk=\(row["pk"] as Int)"
            }
        }
        #expect(columns == [
            "date TEXT notnull=1 pk=1",
            "habit_id TEXT notnull=1 pk=2",
            "value REAL notnull=0 pk=0",
            "detail TEXT notnull=0 pk=0",
            "logged_at TEXT notnull=1 pk=0",
            "source TEXT notnull=1 pk=0",
        ])
    }

    @Test func opensAFileDatabaseWithARollbackJournalAndBusyTimeout() throws {
        let folder = URL.temporaryDirectory.appending(path: "habit-db-\(UUID().uuidString)")
        defer { try? FileManager.default.removeItem(at: folder) }

        let fileDatabase = try AppDatabase.open(at: folder.appending(path: "habits.sqlite"))
        let (journalMode, busyTimeout) = try fileDatabase.writer.read { db in
            try (String.fetchOne(db, sql: "PRAGMA journal_mode"), Int.fetchOne(db, sql: "PRAGMA busy_timeout"))
        }
        #expect(journalMode == "delete")
        #expect(busyTimeout == 2000)
    }
}
