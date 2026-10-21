public enum ReminderKind: String, Sendable, CaseIterable {
    /// At the reminder time.
    case reminder
    /// Once, a while after the reminder, if the group is still unlogged.
    case followUp = "followup"
    /// Sent on wake or launch in place of a reminder the Mac slept through.
    case catchUp = "catchup"
}
