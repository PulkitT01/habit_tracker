import AppKit
import HabitCore

/// What the reminder planner needs from the store, and opening the popover from a notification.
extension HabitStore {
    var todayReminderGroups: [ReminderGroup] {
        reminderGroups(on: today, loggedHabitIDs: todayLoggedHabitIDs, status: todayStatus)
    }

    var tomorrowReminderGroups: [ReminderGroup] {
        reminderGroups(on: today.adding(days: 1), loggedHabitIDs: [], status: nil)
    }

    /// Opens the popover, on `day` if the notification was about another day.
    func openPopover(on day: Day?) {
        NSApp.activate()
        isPopoverPresented = true
        if let day {
            select(day)
        }
    }

    private func reminderGroups(on day: Day, loggedHabitIDs: Set<String>, status: DayStatus?) -> [ReminderGroup] {
        Prompt.allCases.compactMap { prompt in
            let habits = config.habits(activeOn: day, prompt: prompt)
            guard !habits.isEmpty else { return nil }
            return ReminderGroup(
                prompt: prompt,
                isLogged: status?.state(of: prompt) == .logged,
                pendingHabitNames: habits.filter { !loggedHabitIDs.contains($0.id) }.map(\.name)
            )
        }
    }
}
