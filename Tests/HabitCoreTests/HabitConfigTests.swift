import Foundation
import Testing
@testable import HabitCore

@Suite struct HabitConfigTests {
    private static let minimalHabit =
        #"{"id":"read","name":"Read","type":"binary","prompt":"evening","order":10,"active_from":"2026-10-20"}"#

    private func document(_ habits: String...) -> Data {
        Data(#"{"habits":[\#(habits.joined(separator: ","))]}"#.utf8)
    }

    @Test func parsesTheSeedConfig() throws {
        let start = try day("2026-10-20")
        let config = try HabitConfig.parse(Data(SeedConfig.json(activeFrom: start).utf8))

        #expect(config.habits.map(\.id) == [
            "weight", "sleep", "stretching", "creatine",
            "pushups", "squats", "dead_hang", "negatives", "applications", "study", "read", "socializing",
        ])
        #expect(config.habits.allSatisfy { $0.activeFrom == start && $0.activeTo == nil })

        let weight = try #require(config.habit(id: "weight"))
        #expect(weight.type == .number)
        #expect(weight.unit == "kg")
        #expect(weight.decimals == 1)
        #expect(weight.showsTrend)
        #expect(weight.prompt == .morning)

        #expect(config.habit(id: "sleep")?.type == .sleep)
        #expect(config.habit(id: "pushups")?.minTarget == 5)
        #expect(config.habit(id: "squats")?.minTarget == 5)
        #expect(config.habit(id: "dead_hang")?.unit == "s")
        #expect(config.habit(id: "negatives")?.minTarget == nil)

        let socializing = try #require(config.habit(id: "socializing"))
        #expect(socializing.type == .binary)
        #expect(socializing.tags == ["india", "here", "new people"])
        #expect(socializing.description?.contains("girlfriend doesn't count") == true)
    }

    @Test func appliesDefaultsForOptionalFields() throws {
        let habit = try #require(HabitConfig.parse(document(Self.minimalHabit)).habits.first)
        #expect(habit.description == nil)
        #expect(habit.unit == nil)
        #expect(habit.decimals == 0)
        #expect(habit.minTarget == nil)
        #expect(habit.showsTrend == false)
        #expect(habit.activeTo == nil)
        #expect(habit.tags.isEmpty)
    }

    @Test func parsesEveryField() throws {
        let json = """
            {"id":"weight","name":"Weight","description":"Before breakfast","type":"number","unit":"kg",
             "decimals":1,"min_target":60.5,"trend":true,"prompt":"morning","order":5,
             "active_from":"2026-10-01","active_to":"2026-12-31"}
            """
        let habit = try #require(HabitConfig.parse(document(json)).habits.first)
        let expected = try Habit(
            id: "weight", name: "Weight", description: "Before breakfast", type: .number, unit: "kg",
            decimals: 1, minTarget: 60.5, showsTrend: true, prompt: .morning, order: 5,
            activeFrom: day("2026-10-01"), activeTo: day("2026-12-31")
        )
        #expect(habit == expected)
    }

    @Test func sortsByPromptThenOrderThenID() throws {
        let config = try HabitConfig.parse(document(
            #"{"id":"b","name":"B","type":"binary","prompt":"evening","order":1,"active_from":"2026-10-20"}"#,
            #"{"id":"a","name":"A","type":"binary","prompt":"evening","order":1,"active_from":"2026-10-20"}"#,
            #"{"id":"z","name":"Z","type":"binary","prompt":"morning","order":99,"active_from":"2026-10-20"}"#,
            #"{"id":"c","name":"C","type":"binary","prompt":"evening","order":0,"active_from":"2026-10-20"}"#
        ))
        #expect(config.habits.map(\.id) == ["z", "c", "a", "b"])
    }

    @Test func filtersHabitsActiveOnADay() throws {
        let config = try HabitConfig.parse(document(
            #"{"id":"old","name":"Old","type":"binary","prompt":"morning","order":1,"active_from":"2026-01-01","active_to":"2026-10-19"}"#,
            #"{"id":"now","name":"Now","type":"binary","prompt":"evening","order":1,"active_from":"2026-10-20"}"#
        ))
        #expect(try config.habits(activeOn: day("2026-10-19")).map(\.id) == ["old"])
        #expect(try config.habits(activeOn: day("2026-10-20")).map(\.id) == ["now"])
        #expect(try config.habits(activeOn: day("2025-12-31")).isEmpty)
        #expect(try config.habits(activeOn: day("2026-10-20"), prompt: .morning).isEmpty)
    }

    @Test(arguments: [
        (#"{"id":"pushups","name":"Push-ups","type":"count","min_targt":5,"prompt":"evening","order":1,"active_from":"2026-10-20"}"#,
         "habit 'pushups': unknown key 'min_targt'"),
        (#"{"name":"Read","type":"binary","prompt":"evening","order":1,"active_from":"2026-10-20"}"#,
         "habit #1: missing 'id'"),
        (#"{"id":"read","type":"binary","prompt":"evening","order":1,"active_from":"2026-10-20"}"#,
         "habit 'read': missing 'name'"),
        (#"{"id":"Read Books","name":"Read","type":"binary","prompt":"evening","order":1,"active_from":"2026-10-20"}"#,
         "habit 'Read Books': 'id' may only use a–z, 0–9 and _"),
        (#"{"id":"read","name":"Read","type":"boolean","prompt":"evening","order":1,"active_from":"2026-10-20"}"#,
         "habit 'read': 'type' must be binary, count, number or sleep (got 'boolean')"),
        (#"{"id":"read","name":"Read","type":"binary","prompt":"noon","order":1,"active_from":"2026-10-20"}"#,
         "habit 'read': 'prompt' must be morning or evening (got 'noon')"),
        (#"{"id":"read","name":"Read","type":"binary","prompt":"evening","active_from":"2026-10-20"}"#,
         "habit 'read': missing 'order'"),
        (#"{"id":"read","name":"Read","type":"binary","prompt":"evening","order":1,"active_from":"20/10/2026"}"#,
         "habit 'read': 'active_from' must be a date like 2026-10-20 (got '20/10/2026')"),
        (#"{"id":"read","name":"Read","type":"binary","prompt":"evening","order":1,"active_from":"2026-10-20","active_to":"2026-10-19"}"#,
         "habit 'read': 'active_to' is before 'active_from'"),
        (#"{"id":"pushups","name":"Push-ups","type":"count","decimals":1,"prompt":"evening","order":1,"active_from":"2026-10-20"}"#,
         "habit 'pushups': 'decimals' only applies to number habits"),
        (#"{"id":"weight","name":"Weight","type":"number","decimals":7,"prompt":"morning","order":1,"active_from":"2026-10-20"}"#,
         "habit 'weight': 'decimals' must be between 0 and 3"),
        (#"{"id":"read","name":"Read","type":"binary","min_target":1,"prompt":"evening","order":1,"active_from":"2026-10-20"}"#,
         "habit 'read': 'min_target' doesn't apply to binary habits"),
        (#"{"id":"pushups","name":"Push-ups","type":"count","min_target":0,"prompt":"evening","order":1,"active_from":"2026-10-20"}"#,
         "habit 'pushups': 'min_target' must be greater than 0"),
        (#"{"id":"read","name":"Read","type":"binary","trend":true,"prompt":"evening","order":1,"active_from":"2026-10-20"}"#,
         "habit 'read': 'trend' only applies to number habits"),
        (#"{"id":"pushups","name":"Push-ups","type":"count","tags":["a"],"prompt":"evening","order":1,"active_from":"2026-10-20"}"#,
         "habit 'pushups': 'tags' only apply to binary habits"),
        (#"{"id":"social","name":"Social","type":"binary","tags":["india,here"],"prompt":"evening","order":1,"active_from":"2026-10-20"}"#,
         "habit 'social': tags can't be empty or contain commas"),
        (#"{"id":"social","name":"Social","type":"binary","tags":["here","here"],"prompt":"evening","order":1,"active_from":"2026-10-20"}"#,
         "habit 'social': duplicate tag 'here'"),
        (#"{"id":"read","name":"Read","type":"binary","prompt":"evening","order":"10","active_from":"2026-10-20"}"#,
         "habits[0].order: expected a number"),
        (#"{"id":"read","name":"Read","type":"binary","prompt":"evening","order":1.5,"active_from":"2026-10-20"}"#,
         "habit 'read': 'order' must be a whole number"),
    ])
    func reportsReadableValidationErrors(habitJSON: String, expected: String) {
        #expect(throws: ConfigError(message: expected)) {
            try HabitConfig.parse(document(habitJSON))
        }
    }

    @Test func rejectsDuplicateIDs() {
        #expect(throws: ConfigError(message: "habit 'read': duplicate id")) {
            try HabitConfig.parse(document(Self.minimalHabit, Self.minimalHabit))
        }
    }

    @Test func rejectsUnknownTopLevelKeys() {
        let data = Data(#"{"habits":[], "habbits":[]}"#.utf8)
        #expect(throws: ConfigError(message: "habits.json: unknown key 'habbits'")) {
            try HabitConfig.parse(data)
        }
    }

    @Test func requiresAHabitsList() {
        #expect(throws: ConfigError(message: #"habits.json needs a "habits" list"#)) {
            try HabitConfig.parse(Data("{}".utf8))
        }
    }

    @Test func reportsMalformedJSON() throws {
        let error = try #require(throws: ConfigError.self) {
            try HabitConfig.parse(Data(#"{"habits": [ {"id": "read",, } ]}"#.utf8))
        }
        #expect(error.message.hasPrefix("habits.json isn't valid JSON"))
    }

    @Test func reportsAMissingFile() throws {
        let url = URL.temporaryDirectory.appending(path: "missing-\(UUID().uuidString)/habits.json")
        let error = try #require(throws: ConfigError.self) {
            try HabitConfig.load(from: url)
        }
        #expect(error.message.hasPrefix("habits.json not found"))
    }

    @Test func loadsAConfigFile() throws {
        let folder = URL.temporaryDirectory.appending(path: "habit-config-\(UUID().uuidString)")
        try FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: folder) }
        let url = folder.appending(path: "habits.json")
        try document(Self.minimalHabit).write(to: url)

        #expect(try HabitConfig.load(from: url).habits.map(\.id) == ["read"])
    }
}
