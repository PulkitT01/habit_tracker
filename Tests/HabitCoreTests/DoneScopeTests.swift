import Foundation
import Testing
@testable import HabitCore

@Suite struct DoneScopeTests {
    private let boundary: DayBoundary
    private let today: Day
    private let eveningReminder: Date

    init() throws {
        boundary = DayBoundary(timeZone: try zone("Europe/Berlin"))
        today = try day("2026-10-20")
        eveningReminder = boundary.date(for: today, at: TimeOfDay(hour: 21, minute: 30))
    }

    @Test func fillsEveryGroupForAPastDay() throws {
        let prompts = try DoneScope.prompts(
            for: day("2026-10-19"), today: today, now: instant("2026-10-20T07:00:00Z"),
            eveningReminder: eveningReminder, startedPrompts: []
        )
        #expect(prompts == [.morning, .evening])
    }

    @Test func fillsOnlyTheMorningEarlyInTheDay() throws {
        let prompts = try DoneScope.prompts(
            for: today, today: today, now: instant("2026-10-20T07:00:00Z"), // 09:00
            eveningReminder: eveningReminder, startedPrompts: [.morning]
        )
        #expect(prompts == [.morning])
    }

    @Test func fillsTheEveningOnceAnEveningHabitIsLogged() throws {
        let prompts = try DoneScope.prompts(
            for: today, today: today, now: instant("2026-10-20T18:00:00Z"), // 20:00
            eveningReminder: eveningReminder, startedPrompts: [.evening]
        )
        #expect(prompts == [.morning, .evening])
    }

    @Test func fillsTheEveningAfterTheEveningReminder() throws {
        let prompts = try DoneScope.prompts(
            for: today, today: today, now: instant("2026-10-20T19:45:00Z"), // 21:45
            eveningReminder: eveningReminder, startedPrompts: []
        )
        #expect(prompts == [.morning, .evening])
    }

    @Test func stillCountsAsEveningAfterMidnight() throws {
        // 01:00 on Oct 21 is still logical Oct 20, and long after 21:30.
        let now = try instant("2026-10-20T23:00:00Z")
        #expect(boundary.day(containing: now) == today)
        let prompts = DoneScope.prompts(for: today, today: today, now: now, eveningReminder: eveningReminder, startedPrompts: [])
        #expect(prompts == [.morning, .evening])
    }

    @Test func fillsNothingForAFutureDay() throws {
        let prompts = try DoneScope.prompts(
            for: day("2026-10-21"), today: today, now: instant("2026-10-20T19:45:00Z"),
            eveningReminder: eveningReminder, startedPrompts: []
        )
        #expect(prompts.isEmpty)
    }

    @Test func fillsOnlyUnloggedBinaryAndCountHabitsInScope() throws {
        let habits = [
            try habit("weight", .number, prompt: .morning),
            try habit("sleep", .sleep, prompt: .morning),
            try habit("stretching", .binary, prompt: .morning),
            try habit("creatine", .binary, prompt: .morning),
            try habit("pushups", .count, prompt: .evening),
            try habit("later", .binary, prompt: .morning, from: "2026-10-25"),
        ]
        let toFill = DoneScope.habitsToFill(habits, on: today, prompts: [.morning], loggedHabitIDs: ["creatine"])
        #expect(toFill.map(\.id) == ["stretching"])
    }
}
