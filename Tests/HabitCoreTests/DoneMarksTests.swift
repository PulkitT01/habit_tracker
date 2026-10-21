import Foundation
import Testing
@testable import HabitCore

@Suite struct DoneMarksTests {
    @Test func recordsPromptsPerDay() throws {
        let marks = try DoneMarks()
            .marking([.morning], on: day("2026-10-20"))
            .marking([.evening], on: day("2026-10-20"))
            .marking([.morning], on: day("2026-10-19"))

        #expect(try marks.prompts(on: day("2026-10-20")) == [.morning, .evening])
        #expect(try marks.prompts(on: day("2026-10-19")) == [.morning])
        #expect(try marks.prompts(on: day("2026-10-18")).isEmpty)
    }

    @Test func markingReturnsANewValue() throws {
        let original = DoneMarks()
        _ = try original.marking([.morning], on: day("2026-10-20"))
        #expect(try original.prompts(on: day("2026-10-20")).isEmpty)
    }

    @Test func pruningDropsOlderDays() throws {
        let marks = try DoneMarks()
            .marking([.morning], on: day("2026-08-01"))
            .marking([.evening], on: day("2026-10-20"))
            .pruned(before: day("2026-08-21"))

        #expect(try marks.prompts(on: day("2026-08-01")).isEmpty)
        #expect(try marks.prompts(on: day("2026-10-20")) == [.evening])
    }

    @Test func roundTripsThroughJSON() throws {
        let marks = try DoneMarks().marking([.morning, .evening], on: day("2026-10-20"))
        let decoded = try JSONDecoder().decode(DoneMarks.self, from: JSONEncoder().encode(marks))
        #expect(decoded == marks)
    }
}
