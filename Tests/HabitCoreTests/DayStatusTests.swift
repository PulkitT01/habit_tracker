import Testing
@testable import HabitCore

@Suite struct DayStatusTests {
    private let habits: [Habit]

    init() throws {
        habits = [
            try habit("weight", .number, prompt: .morning),
            try habit("stretching", .binary, prompt: .morning),
            try habit("pushups", .count, prompt: .evening, minTarget: 5),
            try habit("read", .binary, prompt: .evening),
        ]
    }

    @Test func isLoggedWhenEveryActiveHabitHasAValue() throws {
        let status = try DayStatus(day: day("2026-10-20"), habits: habits, loggedHabitIDs: ["weight", "stretching", "pushups", "read"], doneMarks: [])
        #expect(status.state(of: .morning) == .logged)
        #expect(status.state(of: .evening) == .logged)
        #expect(status.overall == .logged)
        #expect(status.loggedHabitCount == 4)
        #expect(status.activeHabitCount == 4)
    }

    @Test func distinguishesEmptyAndPartialGroups() throws {
        let status = try DayStatus(day: day("2026-10-20"), habits: habits, loggedHabitIDs: ["stretching"], doneMarks: [])
        #expect(status.state(of: .morning) == .partial)
        #expect(status.state(of: .evening) == .empty)
        #expect(status.overall == .partial)
    }

    @Test func isEmptyWhenNothingIsLoggedOrMarked() throws {
        let status = try DayStatus(day: day("2026-10-20"), habits: habits, loggedHabitIDs: [], doneMarks: [])
        #expect(status.overall == .empty)
        #expect(status.loggedHabitCount == 0)
    }

    @Test func aDoneMarkLogsAGroupWithAMissingMeasurement() throws {
        // Weight wasn't measured, but Done was pressed for the morning.
        let status = try DayStatus(day: day("2026-10-20"), habits: habits, loggedHabitIDs: ["stretching"], doneMarks: [.morning])
        #expect(status.state(of: .morning) == .logged)
        #expect(status.state(of: .evening) == .empty)
        #expect(status.overall == .partial)
    }

    @Test func aDoneMarkAloneMakesTheDayPartial() throws {
        let status = try DayStatus(day: day("2026-10-20"), habits: habits, loggedHabitIDs: [], doneMarks: [.evening])
        #expect(status.overall == .partial)
    }

    @Test func habitsThatArentActiveDontCount() throws {
        let mixed = habits + [try habit("meditate", prompt: .morning, from: "2026-10-21")]
        let status = try DayStatus(day: day("2026-10-20"), habits: mixed, loggedHabitIDs: ["weight", "stretching"], doneMarks: [])
        #expect(status.state(of: .morning) == .logged)
        #expect(status.activeHabitCount == 4)
    }

    @Test func groupsWithoutActiveHabitsAreNotApplicable() throws {
        let morningOnly = [try habit("weight", .number, prompt: .morning)]
        let status = try DayStatus(day: day("2026-10-20"), habits: morningOnly, loggedHabitIDs: ["weight"], doneMarks: [])
        #expect(status.state(of: .evening) == .notApplicable)
        #expect(status.overall == .logged)
    }

    @Test func daysBeforeTrackingStartsAreNotApplicable() throws {
        let status = try DayStatus(day: day("2026-09-30"), habits: habits, loggedHabitIDs: [], doneMarks: [])
        #expect(status.overall == .notApplicable)
        #expect(status.activeHabitCount == 0)
    }
}
