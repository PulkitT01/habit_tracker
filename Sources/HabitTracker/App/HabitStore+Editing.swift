import Foundation
import HabitCore

/// Edits to the selected day. Each one saves immediately, then refreshes status and reminders.
extension HabitStore {
    func setBinary(_ habit: Habit, isOn: Bool) {
        // Unchecking means "logged, didn't do it", so it writes 0 and drops any tags.
        save(habit, value: isOn ? 1 : 0, detail: isOn ? entries[habit.id]?.detail : nil)
    }

    /// Picking a tag also marks the habit done.
    func setTag(_ tag: String, of habit: Habit, selected: Bool) {
        var chosen = Set(selectedTags(of: habit))
        if selected {
            chosen.insert(tag)
        } else {
            chosen.remove(tag)
        }
        // Configured tags in config order, then any stored tags that habits.json no longer lists.
        let retired = selectedTags(of: habit).filter { !habit.tags.contains($0) }
        let detail = (habit.tags.filter(chosen.contains) + retired).joined(separator: ",")
        save(habit, value: selected ? 1 : (value(of: habit) ?? 1), detail: detail.isEmpty ? nil : detail)
    }

    func setCount(_ habit: Habit, to count: Int?) {
        guard let count else { return clear(habit) }
        save(habit, value: Double(count))
    }

    /// + on an empty count logs 1.
    func increment(_ habit: Habit) {
        setCount(habit, to: (currentCount(of: habit) ?? 0) + 1)
    }

    /// − on an empty count logs 0 ("didn't do any").
    func decrement(_ habit: Habit) {
        setCount(habit, to: max(0, (currentCount(of: habit) ?? 1) - 1))
    }

    func setNumber(_ habit: Habit, to number: Double?) {
        guard let number else { return clear(habit) }
        save(habit, value: NumberInput.rounded(number, decimals: habit.decimals))
    }

    func setSleep(_ habit: Habit, to log: SleepLog) {
        save(habit, value: log.hours(wakeDay: selectedDay, timeZone: .autoupdatingCurrent), detail: log.detail)
    }

    /// Back to "not logged": deletes the row.
    func clear(_ habit: Habit) {
        perform("clear \(habit.name)") {
            try repository.deleteEntry(on: selectedDay, habitId: habit.id)
        }
    }

    /// Writes 0 for untouched binary and count habits in the groups Done applies to, marks those
    /// groups finished, and closes the popover. Measurements (number, sleep) are never filled.
    func done(now: Date = .now) {
        let day = selectedDay
        let boundary = DayBoundary(timeZone: .autoupdatingCurrent)
        let eveningReminder = boundary.date(for: today, at: settings.eveningReminder)
        let started = Set(config.habits(activeOn: day).filter { entries[$0.id] != nil }.map(\.prompt))
        let prompts = DoneScope.prompts(for: day, today: today, now: now, eveningReminder: eveningReminder, startedPrompts: started)
        let toFill = DoneScope.habitsToFill(config.habits, on: day, prompts: prompts, loggedHabitIDs: Set(entries.keys))
        let retentionStart = today.adding(days: -DoneMarks.retentionDays)

        perform("finish \(day)") {
            try repository.fillZeros(on: day, habitIds: toFill.map(\.id), loggedAt: Timestamp.string(from: now, timeZone: .autoupdatingCurrent))
            doneMarks = doneMarks.marking(prompts, on: day).pruned(before: retentionStart)
            try saveDoneMarks()
        }
        if errorMessage == nil {
            isPopoverPresented = false
        }
    }

    // MARK: - Helpers

    private func save(_ habit: Habit, value: Double, detail: String? = nil) {
        let entry = Entry(
            date: selectedDay,
            habitId: habit.id,
            value: value,
            detail: detail,
            loggedAt: Timestamp.string(from: .now, timeZone: .autoupdatingCurrent),
            source: EntrySource.manual
        )
        perform("save \(habit.name)") {
            try repository.save(entry)
        }
    }

    private func perform(_ action: String, _ write: () throws -> Void) {
        do {
            try write()
            errorMessage = nil
        } catch {
            report(error, doing: action)
        }
        reloadEntries()
        refreshStatuses()
        refreshStatsIfVisible()
        onRemindersNeedUpdate?()
    }

    private func currentCount(of habit: Habit) -> Int? {
        value(of: habit).flatMap { Int(exactly: $0.rounded()) }
    }
}
