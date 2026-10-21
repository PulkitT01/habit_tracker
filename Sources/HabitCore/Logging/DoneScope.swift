import Foundation

/// Decides what the Done button fills with 0 and marks as finished.
public enum DoneScope {
    /// Groups Done applies to on `day`: every group for a past day; for today the morning,
    /// plus the evening once an evening habit is logged or the evening reminder time has passed.
    /// `eveningReminder` is an absolute date, so 01:00 still counts as "after 21:30".
    public static func prompts(
        for day: Day, today: Day, now: Date, eveningReminder: Date, startedPrompts: Set<Prompt>
    ) -> Set<Prompt> {
        if day < today { return Set(Prompt.allCases) }
        guard day == today else { return [] }
        let eveningIsDue = startedPrompts.contains(.evening) || now >= eveningReminder
        return eveningIsDue ? [.morning, .evening] : [.morning]
    }

    /// Habits Done writes 0 for: active on `day`, in one of `prompts`, binary or count, and not logged.
    public static func habitsToFill(_ habits: [Habit], on day: Day, prompts: Set<Prompt>, loggedHabitIDs: Set<String>) -> [Habit] {
        habits.filter { habit in
            habit.isActive(on: day)
                && prompts.contains(habit.prompt)
                && habit.type.isAutoZeroed
                && !loggedHabitIDs.contains(habit.id)
        }
    }
}
