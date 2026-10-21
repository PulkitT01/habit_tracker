import Foundation
import Testing
@testable import HabitCore

@Suite struct ExporterTests {
    @Test(arguments: [
        ("plain", "plain"),
        ("india,here", #""india,here""#),
        (#"say "hi""#, #""say ""hi""""#),
        ("two\nlines", "\"two\nlines\""),
        ("", ""),
    ])
    func quotesFieldsOnlyWhenNeeded(raw: String, expected: String) {
        #expect(CSVWriter.field(raw) == expected)
    }

    @Test func writesNullAsAnEmptyField() {
        #expect(CSVWriter.line(["2026-10-20", nil, "x"]) == "2026-10-20,,x")
    }

    @Test func exportsEntriesInLongFormat() throws {
        let entries = try [
            Entry(date: day("2026-10-20"), habitId: "sleep", value: 7.75, detail: "23:30-07:15",
                  loggedAt: "2026-10-20T08:01:00+02:00", source: EntrySource.manual),
            Entry(date: day("2026-10-20"), habitId: "socializing", value: 1, detail: "india,new people",
                  loggedAt: "2026-10-20T22:00:00+02:00", source: EntrySource.manual),
            Entry(date: day("2026-10-20"), habitId: "study", value: 0, loggedAt: "2026-10-20T22:00:05+02:00", source: EntrySource.autoZero),
            Entry(date: day("2026-10-20"), habitId: "weight", value: nil, loggedAt: "2026-10-20T08:00:00Z", source: "import"),
        ]
        #expect(Exporter.entriesCSV(entries) == """
            date,habit_id,value,detail,logged_at,source
            2026-10-20,sleep,7.75,23:30-07:15,2026-10-20T08:01:00+02:00,manual
            2026-10-20,socializing,1.0,"india,new people",2026-10-20T22:00:00+02:00,manual
            2026-10-20,study,0.0,,2026-10-20T22:00:05+02:00,auto_zero
            2026-10-20,weight,,,2026-10-20T08:00:00Z,import

            """)
    }

    @Test func exportsDayNotes() throws {
        let notes = try [DayNote(date: day("2026-10-19"), note: "sick, stayed in"), DayNote(date: day("2026-10-20"), note: "travelling")]
        #expect(Exporter.notesCSV(notes) == """
            date,note
            2026-10-19,"sick, stayed in"
            2026-10-20,travelling

            """)
    }

    @Test func writesBothFilesToTheChosenFolder() throws {
        let repository = EntryRepository(try AppDatabase.inMemory())
        try repository.save(Entry(date: day("2026-10-20"), habitId: "read", value: 1, loggedAt: "2026-10-20T21:00:00+02:00", source: EntrySource.manual))
        try repository.setNote("travelling", on: day("2026-10-20"))
        let folder = URL.temporaryDirectory.appending(path: "habit-export-\(UUID().uuidString)")
        try FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: folder) }
        try "stale".write(to: folder.appending(path: Exporter.entriesFileName), atomically: true, encoding: .utf8)

        let summary = try Exporter.export(from: repository, to: folder)

        #expect(summary.entryCount == 1)
        #expect(summary.noteCount == 1)
        let entries = try String(contentsOf: folder.appending(path: Exporter.entriesFileName), encoding: .utf8)
        #expect(entries.hasPrefix("date,habit_id,value,detail,logged_at,source\n2026-10-20,read,1.0,"))
        let notes = try String(contentsOf: folder.appending(path: Exporter.notesFileName), encoding: .utf8)
        #expect(notes == "date,note\n2026-10-20,travelling\n")
    }
}
