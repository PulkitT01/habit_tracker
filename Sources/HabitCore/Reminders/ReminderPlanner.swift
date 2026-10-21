import Foundation

/// Decides which reminder notifications should exist right now.
///
/// Reminders are scheduled with the system ahead of time. Follow-ups and catch-ups are worked
/// out here, because the Mac may sleep through either:
/// - A reminder missed while asleep becomes one catch-up on wake, for the most recent due group only.
/// - The follow-up comes `followUpMinutes` after the reminder was actually shown, at most once a day.
/// - A logged group gets nothing.
public struct ReminderPlanner: Sendable {
    public let boundary: DayBoundary
    public let settings: ReminderSettings

    public init(boundary: DayBoundary, settings: ReminderSettings) {
        self.boundary = boundary
        self.settings = settings
    }

    /// - Parameters:
    ///   - groups: today's groups that have active habits.
    ///   - tomorrowGroups: tomorrow's groups that have active habits.
    ///   - delivered: notification id → delivery date, from Notification Center.
    ///   - awakeSince: when the app last launched or the Mac last woke.
    public func plan(
        now: Date,
        today: Day,
        groups: [ReminderGroup],
        tomorrowGroups: [ReminderGroup],
        log: ReminderLog,
        delivered: [String: Date],
        awakeSince: Date
    ) -> ReminderPlan {
        let latestDue = groups
            .filter { reminderDate(on: today, for: $0.prompt) <= now }
            .max { reminderDate(on: today, for: $0.prompt) < reminderDate(on: today, for: $1.prompt) }?
            .prompt

        var scheduled: [PlannedNotification] = []
        var immediate: [PlannedNotification] = []
        var updatedLog = log
        for group in groups where !group.isLogged {
            let outcome = planToday(
                group, today: today, now: now, isLatestDue: group.prompt == latestDue,
                record: log.record(day: today, prompt: group.prompt), delivered: delivered, awakeSince: awakeSince
            )
            scheduled += outcome.scheduled
            immediate += outcome.immediate
            if let record = outcome.record {
                updatedLog = updatedLog.setting(record, day: today, prompt: group.prompt)
            }
        }

        let tomorrow = today.adding(days: 1)
        scheduled += tomorrowGroups.map { group in
            notification(.reminder, on: tomorrow, for: group, at: reminderDate(on: tomorrow, for: group.prompt))
        }

        return ReminderPlan(
            scheduled: scheduled,
            immediate: immediate,
            resolvedPrompts: Set(groups.filter(\.isLogged).map(\.prompt)),
            log: updatedLog.pruned(before: today.adding(days: -1))
        )
    }

    private func planToday(
        _ group: ReminderGroup,
        today: Day,
        now: Date,
        isLatestDue: Bool,
        record: ReminderRecord,
        delivered: [String: Date],
        awakeSince: Date
    ) -> (scheduled: [PlannedNotification], immediate: [PlannedNotification], record: ReminderRecord?) {
        let reminderAt = reminderDate(on: today, for: group.prompt)
        guard now >= reminderAt else {
            let reminder = notification(.reminder, on: today, for: group, at: reminderAt)
            let followUp = notification(.followUp, on: today, for: group, at: reminderAt.addingTimeInterval(followUpDelay))
            return ([reminder, followUp], [], nil)
        }

        // Was the reminder shown? Known from the log, Notification Center, or because we were awake.
        var immediate: [PlannedNotification] = []
        var shown = record.shownAt
            ?? delivered[PlannedNotification.id(.reminder, today, group.prompt)]
            ?? (awakeSince <= reminderAt ? reminderAt : nil)
        if shown == nil, isLatestDue {
            immediate.append(notification(.catchUp, on: today, for: group, at: nil))
            shown = now
        }
        guard let shownAt = shown else { return ([], [], nil) }

        let followUpAt = record.followUpDueAt ?? shownAt.addingTimeInterval(followUpDelay)
        if record.followUpSent {
            return ([], immediate, ReminderRecord(shownAt: shownAt, followUpDueAt: followUpAt, followUpSent: true))
        }
        if followUpAt > now {
            let followUp = notification(.followUp, on: today, for: group, at: followUpAt)
            return ([followUp], immediate, ReminderRecord(shownAt: shownAt, followUpDueAt: followUpAt, followUpSent: false))
        }
        // The follow-up time has passed: it showed if we were awake for it, otherwise send it now.
        let followUpShown = delivered[PlannedNotification.id(.followUp, today, group.prompt)] != nil || awakeSince <= followUpAt
        if !followUpShown {
            immediate.append(notification(.followUp, on: today, for: group, at: nil))
        }
        return ([], immediate, ReminderRecord(shownAt: shownAt, followUpDueAt: followUpAt, followUpSent: true))
    }

    private var followUpDelay: TimeInterval {
        TimeInterval(settings.followUpMinutes * 60)
    }

    private func reminderDate(on day: Day, for prompt: Prompt) -> Date {
        boundary.date(for: day, at: settings.time(for: prompt))
    }

    private func notification(_ kind: ReminderKind, on day: Day, for group: ReminderGroup, at date: Date?) -> PlannedNotification {
        PlannedNotification(kind: kind, day: day, prompt: group.prompt, fireDate: date, habitNames: group.pendingHabitNames)
    }
}
