import Foundation
import Testing
@testable import HabitCore

/// Berlin, Tuesday 2026-10-20 (UTC+2). Morning reminder 08:30 = 06:30Z, evening 21:30 = 19:30Z.
@Suite struct ReminderPlannerTests {
    private let planner: ReminderPlanner
    private let today: Day
    private let morning = ReminderGroup(prompt: .morning, isLogged: false, pendingHabitNames: ["Weight", "Stretching"])
    private let evening = ReminderGroup(prompt: .evening, isLogged: false, pendingHabitNames: ["Push-ups", "Read"])

    init() throws {
        let settings = ReminderSettings(
            morning: TimeOfDay(hour: 8, minute: 30), evening: TimeOfDay(hour: 21, minute: 30), followUpMinutes: 45
        )
        planner = ReminderPlanner(boundary: DayBoundary(timeZone: try zone("Europe/Berlin")), settings: settings)
        today = try day("2026-10-20")
    }

    private func plan(
        now: String,
        awakeSince: String = "2026-10-20T04:00:00Z",
        groups: [ReminderGroup]? = nil,
        log: ReminderLog = ReminderLog(),
        delivered: [String: Date] = [:]
    ) throws -> ReminderPlan {
        try planner.plan(
            now: instant(now),
            today: today,
            groups: groups ?? [morning, evening],
            tomorrowGroups: [morning, evening],
            log: log,
            delivered: delivered,
            awakeSince: instant(awakeSince)
        )
    }

    private func summary(_ notifications: [PlannedNotification]) -> [String] {
        notifications.map { notification in
            let time = notification.fireDate.map { $0.formatted(.iso8601) } ?? "now"
            return "\(notification.id) @ \(time)"
        }
    }

    @Test func schedulesRemindersAndFollowUpsAhead() throws {
        let result = try plan(now: "2026-10-20T05:00:00Z") // 07:00
        #expect(summary(result.scheduled) == [
            "reminder.2026-10-20.morning @ 2026-10-20T06:30:00Z",
            "followup.2026-10-20.morning @ 2026-10-20T07:15:00Z",
            "reminder.2026-10-20.evening @ 2026-10-20T19:30:00Z",
            "followup.2026-10-20.evening @ 2026-10-20T20:15:00Z",
            "reminder.2026-10-21.morning @ 2026-10-21T06:30:00Z",
            "reminder.2026-10-21.evening @ 2026-10-21T19:30:00Z",
        ])
        #expect(result.immediate.isEmpty)
        #expect(result.scheduled.first?.habitNames == ["Weight", "Stretching"])
    }

    @Test func leavesLoggedGroupsAlone() throws {
        let logged = ReminderGroup(prompt: .morning, isLogged: true, pendingHabitNames: [])
        let result = try plan(now: "2026-10-20T05:00:00Z", groups: [logged, evening])
        #expect(!result.scheduled.contains { $0.day == today && $0.prompt == .morning })
        #expect(result.resolvedPrompts == [.morning])
    }

    @Test func alwaysPlansTomorrow() throws {
        let done = [ReminderGroup(prompt: .morning, isLogged: true, pendingHabitNames: []),
                    ReminderGroup(prompt: .evening, isLogged: true, pendingHabitNames: [])]
        let result = try plan(now: "2026-10-20T20:00:00Z", groups: done)
        #expect(summary(result.scheduled) == [
            "reminder.2026-10-21.morning @ 2026-10-21T06:30:00Z",
            "reminder.2026-10-21.evening @ 2026-10-21T19:30:00Z",
        ])
    }

    @Test func assumesTheReminderShowedWhileTheMacWasAwake() throws {
        let result = try plan(now: "2026-10-20T06:31:00Z") // 08:31, awake since 06:00
        #expect(result.immediate.isEmpty)
        #expect(summary(result.scheduled).contains("followup.2026-10-20.morning @ 2026-10-20T07:15:00Z"))
        #expect(try result.log.record(day: today, prompt: .morning).shownAt == instant("2026-10-20T06:30:00Z"))
    }

    @Test func catchesUpOnceAfterWakingPastTheReminder() throws {
        // Lid opened at 09:40: one reminder now, the follow-up 45 minutes later.
        let result = try plan(now: "2026-10-20T07:40:00Z", awakeSince: "2026-10-20T07:40:00Z")
        #expect(summary(result.immediate) == ["catchup.2026-10-20.morning @ now"])
        #expect(summary(result.scheduled).contains("followup.2026-10-20.morning @ 2026-10-20T08:25:00Z"))
        #expect(!summary(result.scheduled).contains { $0.hasPrefix("followup.2026-10-20.morning @ 2026-10-20T07:15") })

        // Planning again a minute later doesn't repeat the catch-up.
        let again = try planner.plan(
            now: instant("2026-10-20T07:41:00Z"), today: today, groups: [morning, evening], tomorrowGroups: [morning, evening],
            log: result.log, delivered: [:], awakeSince: instant("2026-10-20T07:40:00Z")
        )
        #expect(again.immediate.isEmpty)
        #expect(summary(again.scheduled).contains("followup.2026-10-20.morning @ 2026-10-20T08:25:00Z"))
    }

    @Test func followsUpFromWhenAMissedReminderWasDelivered() throws {
        let deliveredAt = try instant("2026-10-20T07:39:58Z") // macOS showed it on wake
        let result = try plan(
            now: "2026-10-20T07:40:05Z", awakeSince: "2026-10-20T07:39:55Z",
            delivered: ["reminder.2026-10-20.morning": deliveredAt]
        )
        #expect(result.immediate.isEmpty)
        #expect(result.scheduled.contains { $0.id == "followup.2026-10-20.morning" && $0.fireDate == deliveredAt.addingTimeInterval(45 * 60) })
    }

    @Test func sendsAFollowUpMissedDuringSleepOnce() throws {
        let shown = try ReminderLog().setting(
            ReminderRecord(shownAt: instant("2026-10-20T06:30:00Z"), followUpDueAt: instant("2026-10-20T07:15:00Z"), followUpSent: false),
            day: today, prompt: .morning
        )
        let result = try plan(now: "2026-10-20T07:40:00Z", awakeSince: "2026-10-20T07:39:00Z", log: shown)
        #expect(summary(result.immediate) == ["followup.2026-10-20.morning @ now"])
        #expect(result.log.record(day: today, prompt: .morning).followUpSent)

        let again = try plan(now: "2026-10-20T08:00:00Z", awakeSince: "2026-10-20T07:39:00Z", log: result.log)
        #expect(again.immediate.isEmpty)
        #expect(!again.scheduled.contains { $0.id == "followup.2026-10-20.morning" })
    }

    @Test func countsAFollowUpThatFiredWhileAwakeAsSent() throws {
        let shown = try ReminderLog().setting(
            ReminderRecord(shownAt: instant("2026-10-20T06:30:00Z"), followUpDueAt: instant("2026-10-20T07:15:00Z"), followUpSent: false),
            day: today, prompt: .morning
        )
        let result = try plan(now: "2026-10-20T07:20:00Z", awakeSince: "2026-10-20T05:00:00Z", log: shown)
        #expect(result.immediate.isEmpty)
        #expect(result.log.record(day: today, prompt: .morning).followUpSent)
    }

    @Test func skipsTheStaleMorningCatchUpOnceTheEveningIsDue() throws {
        let result = try plan(now: "2026-10-20T20:00:00Z", awakeSince: "2026-10-20T20:00:00Z") // 22:00, just woke
        #expect(summary(result.immediate) == ["catchup.2026-10-20.evening @ now"])
    }

    @Test func placesRemindersAfterMidnightOnTheSameLogicalDay() throws {
        let lateEvening = ReminderSettings(morning: TimeOfDay(hour: 8, minute: 30), evening: TimeOfDay(hour: 0, minute: 30), followUpMinutes: 45)
        let latePlanner = ReminderPlanner(boundary: DayBoundary(timeZone: try zone("Europe/Berlin")), settings: lateEvening)
        let result = try latePlanner.plan(
            now: instant("2026-10-20T20:00:00Z"), today: today, groups: [evening], tomorrowGroups: [],
            log: ReminderLog(), delivered: [:], awakeSince: instant("2026-10-20T05:00:00Z")
        )
        // 00:30 on the night of Oct 20 is Oct 21 00:30 local = Oct 20 22:30Z.
        #expect(summary(result.scheduled) == [
            "reminder.2026-10-20.evening @ 2026-10-20T22:30:00Z",
            "followup.2026-10-20.evening @ 2026-10-20T23:15:00Z",
        ])
    }

    @Test func keepsOnlyRecentLogRecords() throws {
        let old = try ReminderLog().setting(ReminderRecord(shownAt: nil, followUpDueAt: nil, followUpSent: true), day: day("2026-10-01"), prompt: .morning)
        let result = try plan(now: "2026-10-20T05:00:00Z", log: old)
        #expect(try result.log.record(day: day("2026-10-01"), prompt: .morning) == .empty)
    }

    @Test func reminderLogRoundTripsThroughJSON() throws {
        let log = try ReminderLog().setting(
            ReminderRecord(shownAt: instant("2026-10-20T06:30:00Z"), followUpDueAt: nil, followUpSent: false), day: today, prompt: .evening
        )
        #expect(try JSONDecoder().decode(ReminderLog.self, from: JSONEncoder().encode(log)) == log)
    }

    @Test func aClickedReminderCountsAsShown() throws {
        // The app wasn't running at 08:30; clicking the reminder at 08:35 relaunches it.
        let clicked = try ReminderLog().markingShown(.reminder, day: today, prompt: .morning, at: instant("2026-10-20T06:30:00Z"))
        let result = try plan(now: "2026-10-20T06:35:05Z", awakeSince: "2026-10-20T06:35:00Z", log: clicked)
        #expect(result.immediate.isEmpty)
        #expect(summary(result.scheduled).contains("followup.2026-10-20.morning @ 2026-10-20T07:15:00Z"))
    }

    @Test func aClickedFollowUpIsNeverResent() throws {
        let shown = try ReminderLog()
            .markingShown(.reminder, day: today, prompt: .morning, at: instant("2026-10-20T06:30:00Z"))
            .markingShown(.followUp, day: today, prompt: .morning, at: instant("2026-10-20T07:15:00Z"))
        let result = try plan(now: "2026-10-20T07:20:00Z", awakeSince: "2026-10-20T07:19:00Z", log: shown)
        #expect(result.immediate.isEmpty)
        #expect(!result.scheduled.contains { $0.id == "followup.2026-10-20.morning" })
    }

    @Test func markingKeepsTheFirstShownTime() throws {
        let log = try ReminderLog()
            .markingShown(.reminder, day: today, prompt: .evening, at: instant("2026-10-20T19:30:00Z"))
            .markingShown(.catchUp, day: today, prompt: .evening, at: instant("2026-10-20T20:00:00Z"))
        #expect(try log.record(day: today, prompt: .evening).shownAt == instant("2026-10-20T19:30:00Z"))
    }
}

