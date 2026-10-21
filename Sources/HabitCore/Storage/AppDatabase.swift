import Foundation
import GRDB

/// The SQLite database. The schema is deliberately plain so pandas can read it with `sqlite3`.
/// It uses the default rollback journal, so the file is always self-contained.
public struct AppDatabase: Sendable {
    public static let fileName = "habits.sqlite"
    /// How long a write waits for an external reader (a notebook, DB Browser) to release its lock.
    static let busyTimeout: TimeInterval = 2

    let writer: any DatabaseWriter

    init(_ writer: any DatabaseWriter) throws {
        self.writer = writer
        try Self.migrator.migrate(writer)
    }

    /// Opens the database file, creating it and its folder if needed.
    public static func open(at url: URL) throws -> AppDatabase {
        try FileManager.default.createDirectory(at: url.deletingLastPathComponent(), withIntermediateDirectories: true)
        var configuration = Configuration()
        configuration.busyMode = .timeout(busyTimeout)
        return try AppDatabase(DatabaseQueue(path: url.path(percentEncoded: false), configuration: configuration))
    }

    /// An empty database that lives in memory, for tests.
    public static func inMemory() throws -> AppDatabase {
        try AppDatabase(DatabaseQueue())
    }

    private static var migrator: DatabaseMigrator {
        var migrator = DatabaseMigrator()
        migrator.registerMigration("v1") { db in
            try db.execute(sql: """
                CREATE TABLE entries (
                    date      TEXT NOT NULL,  -- logical day YYYY-MM-DD; a day ends at 04:00 local time
                    habit_id  TEXT NOT NULL,  -- id from habits.json
                    value     REAL,           -- NULL or no row = not logged; 0 = logged, didn't do it
                    detail    TEXT,           -- binary tags "india,here" or sleep "23:30-07:15"
                    logged_at TEXT NOT NULL,  -- ISO 8601 time of the last edit, with UTC offset
                    source    TEXT NOT NULL,  -- 'manual', or 'auto_zero' when filled by Done
                    PRIMARY KEY (date, habit_id)
                );
                CREATE TABLE day_notes (
                    date TEXT NOT NULL PRIMARY KEY,  -- logical day YYYY-MM-DD
                    note TEXT NOT NULL               -- free text such as "sick" or "travelling"
                );
                """)
        }
        return migrator
    }
}
