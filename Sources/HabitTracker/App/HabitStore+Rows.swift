import Foundation
import HabitCore

/// Read access and bindings for the popover's rows, all for the selected day.
extension HabitStore {
    func habits(for prompt: Prompt) -> [Habit] {
        config.habits(activeOn: selectedDay, prompt: prompt)
    }

    func value(of habit: Habit) -> Double? {
        entries[habit.id]?.value
    }

    func dotState(of habit: Habit) -> DotState {
        DotState(habit: habit, day: selectedDay, value: value(of: habit))
    }

    func selectedTags(of habit: Habit) -> [String] {
        entries[habit.id]?.detail?.split(separator: ",").map(String.init) ?? []
    }

    func previousValue(of habit: Habit) -> Double? {
        previousEntries[habit.id]?.value
    }

    /// The logged night, else the previous night's times, else 23:00–07:00.
    func sleepLog(for habit: Habit) -> SleepLog {
        entries[habit.id]?.detail.flatMap(SleepLog.init(detail:))
            ?? previousEntries[habit.id]?.detail.flatMap(SleepLog.init(detail:))
            ?? SleepLog(bedtime: SleepLog.defaultBedtime, wake: SleepLog.defaultWake)
    }

    // MARK: - Bindings

    subscript(isDone habit: Habit) -> Bool {
        get { (value(of: habit) ?? 0) >= 1 }
        set { setBinary(habit, isOn: newValue) }
    }

    subscript(tag tag: String, of habit: Habit) -> Bool {
        get { selectedTags(of: habit).contains(tag) }
        set { setTag(tag, of: habit, selected: newValue) }
    }

    subscript(bedtimeOf habit: Habit) -> Date {
        get { sleepLog(for: habit).bedtime.date(on: selectedDay, in: .autoupdatingCurrent) }
        set { updateSleep(habit, bedtime: TimeOfDay(of: newValue, in: .autoupdatingCurrent)) }
    }

    subscript(wakeOf habit: Habit) -> Date {
        get { sleepLog(for: habit).wake.date(on: selectedDay, in: .autoupdatingCurrent) }
        set { updateSleep(habit, wake: TimeOfDay(of: newValue, in: .autoupdatingCurrent)) }
    }

    /// The selected day as a date-picker value.
    var selectedDate: Date {
        get { selectedDay.noon(in: .autoupdatingCurrent) }
        set { select(Day(calendarDateOf: newValue, in: .autoupdatingCurrent)) }
    }

    var latestSelectableDate: Date {
        today.noon(in: .autoupdatingCurrent)
    }

    var dayChoice: DayChoice {
        get {
            if selectedDay == today {
                .today
            } else if selectedDay == today.adding(days: -1) {
                .yesterday
            } else {
                .other
            }
        }
        set {
            switch newValue {
            case .today: select(today)
            case .yesterday: select(today.adding(days: -1))
            case .other: break
            }
        }
    }

    // MARK: - Status

    var showsYesterdayBanner: Bool {
        selectedDay == today && [.empty, .partial].contains(yesterdayStatus.overall)
    }

    var menuBarSymbol: String {
        if configError != nil, config.habits.isEmpty {
            return "exclamationmark.triangle"
        }
        return switch todayStatus.overall {
        case .empty: "circle"
        case .partial: "circle.lefthalf.filled"
        case .logged, .notApplicable: "checkmark.circle.fill"
        }
    }

    // MARK: - Helpers

    /// Edits one end of the night. While sleep isn't logged, the pickers show suggested times;
    /// leaving a suggestion unchanged doesn't log it (the ✓ button does).
    private func updateSleep(_ habit: Habit, bedtime: TimeOfDay? = nil, wake: TimeOfDay? = nil) {
        let current = sleepLog(for: habit)
        let updated = SleepLog(bedtime: bedtime ?? current.bedtime, wake: wake ?? current.wake)
        guard updated != current || entries[habit.id] != nil else { return }
        setSleep(habit, to: updated)
    }
}
