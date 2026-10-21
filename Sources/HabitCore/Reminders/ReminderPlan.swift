/// The planner's output: what should be pending, what to show now, and the updated log.
public struct ReminderPlan: Sendable, Equatable {
    /// Future notifications; everything else pending should be removed.
    public let scheduled: [PlannedNotification]
    /// Catch-ups and missed follow-ups to deliver right away.
    public let immediate: [PlannedNotification]
    /// Today's groups that are logged: their pending and delivered notifications can go.
    public let resolvedPrompts: Set<Prompt>
    public let log: ReminderLog

    public init(scheduled: [PlannedNotification], immediate: [PlannedNotification], resolvedPrompts: Set<Prompt>, log: ReminderLog) {
        self.scheduled = scheduled
        self.immediate = immediate
        self.resolvedPrompts = resolvedPrompts
        self.log = log
    }
}
