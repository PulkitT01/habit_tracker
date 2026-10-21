import Foundation
import HabitCore
import Observation

/// State behind the popover and the menu-bar icon. Every edit is written to SQLite right away,
/// so closing the popover never loses input.
@Observable
final class HabitStore {
    @ObservationIgnored let paths: AppPaths
    @ObservationIgnored let settings: AppSettings
    @ObservationIgnored let repository: EntryRepository
    @ObservationIgnored private let defaults: UserDefaults
    /// Called when something reminders depend on changes: entries, Done marks, config or today.
    @ObservationIgnored var onRemindersNeedUpdate: (() -> Void)?

    /// Set when the database couldn't be opened; the popover then shows only this error.
    let startupError: String?

    private(set) var config = HabitConfig.empty
    /// Why the last habits.json reload failed; the previous config stays in use.
    private(set) var configError: String?
    /// The last failed save or load, shown in the popover.
    var errorMessage: String?

    private(set) var today: Day
    private(set) var selectedDay: Day
    /// Logged entries for `selectedDay`, by habit id. NULL values never appear here.
    private(set) var entries: [String: Entry] = [:]
    /// Most recent logged entry before `selectedDay` for number and sleep habits (placeholders).
    private(set) var previousEntries: [String: Entry] = [:]
    private(set) var note = ""
    var doneMarks: DoneMarks

    private(set) var todayStatus: DayStatus
    private(set) var todayLoggedHabitIDs: Set<String> = []
    private(set) var yesterdayStatus: DayStatus
    private(set) var stats: StatsSnapshot?

    var selectedTab = PopoverTab.log {
        didSet { if selectedTab == .stats { refreshStats() } }
    }

    /// Bound to the MenuBarExtra window. Opening it always starts on Today's log.
    var isPopoverPresented = false {
        didSet { if isPopoverPresented, !oldValue { popoverDidOpen() } }
    }

    init(
        repository: EntryRepository,
        paths: AppPaths,
        settings: AppSettings,
        startupError: String? = nil,
        defaults: UserDefaults = .standard
    ) {
        self.repository = repository
        self.paths = paths
        self.settings = settings
        self.startupError = startupError
        self.defaults = defaults
        let today = Self.currentDay()
        self.today = today
        self.selectedDay = today
        self.doneMarks = Self.loadDoneMarks(from: defaults)
        let blank = DayStatus(day: today, habits: [], loggedHabitIDs: [], doneMarks: [])
        self.todayStatus = blank
        self.yesterdayStatus = blank
        if startupError == nil {
            seedConfigIfMissing()
        }
        reloadConfig()
    }

    static func currentDay(now: Date = .now) -> Day {
        DayBoundary(timeZone: .autoupdatingCurrent).day(containing: now)
    }

    // MARK: - Config

    /// Re-reads habits.json. On failure the current habits stay and `configError` explains why;
    /// at launch, when there are no current habits yet, the last working copy is used instead.
    func reloadConfig() {
        do {
            let data = try HabitConfig.data(at: paths.config)
            config = try HabitConfig.parse(data)
            configError = nil
            defaults.set(data, forKey: Self.lastGoodConfigKey)
        } catch {
            Log.store.error("habits.json rejected: \(error.localizedDescription, privacy: .public)")
            if config.habits.isEmpty {
                restoreLastGoodConfig()
            }
            let consequence = config.habits.isEmpty
                ? "No habits are loaded until it's fixed."
                : "The last working habits are still in use."
            configError = "\(error.localizedDescription). \(consequence)"
        }
        reloadSelectedDay()
        refreshStatuses()
        refreshStatsIfVisible()
        onRemindersNeedUpdate?()
    }

    private static let lastGoodConfigKey = "lastGoodConfig"

    private func restoreLastGoodConfig() {
        guard let data = defaults.data(forKey: Self.lastGoodConfigKey) else { return }
        do {
            config = try HabitConfig.parse(data)
            Log.store.notice("Using the last working habits.json")
        } catch {
            Log.store.error("The saved copy of habits.json is unreadable too: \(error.localizedDescription, privacy: .public)")
        }
    }

    /// Writes the starter habits.json on first launch. `active_from` is the earliest logged day,
    /// so re-creating a deleted config doesn't hide existing history. Without history it's the
    /// calendar date, so installing at 02:00 starts tracking that morning rather than the day
    /// that is about to end (which would show up as an unlogged yesterday).
    private func seedConfigIfMissing() {
        guard !FileManager.default.fileExists(atPath: paths.config.path(percentEncoded: false)) else { return }
        do {
            let start = try repository.earliestDay() ?? Day(calendarDateOf: .now, in: .autoupdatingCurrent)
            try FileManager.default.createDirectory(at: paths.folder, withIntermediateDirectories: true)
            try SeedConfig.json(activeFrom: start).write(to: paths.config, atomically: true, encoding: .utf8)
            Log.store.notice("Wrote starter habits.json to \(self.paths.config.path(percentEncoded: false), privacy: .public)")
        } catch {
            report(error, doing: "create habits.json")
        }
    }

    // MARK: - Days

    func select(_ day: Day) {
        let clamped = min(day, today)
        guard clamped != selectedDay else { return }
        selectedDay = clamped
        reloadSelectedDay()
    }

    func selectPreviousDay() {
        select(selectedDay.adding(days: -1))
    }

    func selectNextDay() {
        select(selectedDay.adding(days: 1))
    }

    var canSelectNextDay: Bool { selectedDay < today }

    /// Moves `today` forward after 04:00, a wake from sleep or a time-zone change.
    func refreshToday(now: Date = .now) {
        let current = Self.currentDay(now: now)
        guard current != today else { return }
        today = current
        if selectedDay > today { selectedDay = today }
        reloadSelectedDay()
        refreshStatuses()
        refreshStatsIfVisible()
        onRemindersNeedUpdate?()
    }

    private func popoverDidOpen() {
        refreshToday()
        selectedTab = .log
        if selectedDay != today {
            selectedDay = today
        }
        reloadSelectedDay()
        refreshStatuses()
    }

    // MARK: - Loading

    func reloadSelectedDay() {
        reloadEntries()
        do {
            note = try repository.note(on: selectedDay) ?? ""
        } catch {
            report(error, doing: "load the note")
        }
    }

    /// Saves the day note as typed; the database stores it trimmed, and a blank note deletes the row.
    func setNote(_ text: String) {
        note = text
        do {
            try repository.setNote(text, on: selectedDay)
        } catch {
            report(error, doing: "save the note")
        }
    }

    /// Reloads the selected day's entries (not the note, so typing in the note field isn't disturbed).
    func reloadEntries() {
        do {
            entries = try Dictionary(uniqueKeysWithValues: repository.loggedEntries(on: selectedDay).map { ($0.habitId, $0) })
            let measured = config.habits(activeOn: selectedDay).filter { $0.type == .number || $0.type == .sleep }
            previousEntries = try Dictionary(uniqueKeysWithValues: measured.compactMap { habit in
                try repository.latestLoggedEntry(habitId: habit.id, before: selectedDay).map { (habit.id, $0) }
            })
        } catch {
            entries = [:]
            previousEntries = [:]
            report(error, doing: "load \(selectedDay)")
        }
    }

    func refreshStatuses() {
        let yesterday = today.adding(days: -1)
        do {
            let recent = try repository.loggedEntries(from: yesterday, through: today)
            todayLoggedHabitIDs = Set(recent.filter { $0.date == today }.map(\.habitId))
            todayStatus = status(on: today, loggedHabitIDs: todayLoggedHabitIDs)
            yesterdayStatus = status(on: yesterday, loggedHabitIDs: Set(recent.filter { $0.date == yesterday }.map(\.habitId)))
        } catch {
            report(error, doing: "check today's progress")
        }
    }

    func refreshStats() {
        do {
            let recent = try repository.loggedEntries(from: today.adding(days: -StatsSnapshot.historyDays), through: today)
            let trendHabits = config.habits(activeOn: today).filter(\.showsTrend)
            let histories = try Dictionary(uniqueKeysWithValues: trendHabits.map { habit in
                (habit.id, try repository.loggedEntries(habitId: habit.id))
            })
            stats = StatsSnapshot(habits: config.habits(activeOn: today), today: today, recentEntries: recent, trendHistories: histories)
        } catch {
            report(error, doing: "compute stats")
        }
    }

    func refreshStatsIfVisible() {
        if selectedTab == .stats {
            refreshStats()
        }
    }

    func status(on day: Day, loggedHabitIDs: Set<String>) -> DayStatus {
        DayStatus(day: day, habits: config.habits, loggedHabitIDs: loggedHabitIDs, doneMarks: doneMarks.prompts(on: day))
    }

    // MARK: - Errors

    func report(_ error: any Error, doing action: String) {
        Log.store.error("Couldn't \(action, privacy: .public): \(error.localizedDescription, privacy: .public)")
        errorMessage = "Couldn't \(action): \(error.localizedDescription)"
    }

    // MARK: - Done marks

    private static let doneMarksKey = "doneMarks"

    private static func loadDoneMarks(from defaults: UserDefaults) -> DoneMarks {
        guard let data = defaults.data(forKey: doneMarksKey) else { return DoneMarks() }
        do {
            return try JSONDecoder().decode(DoneMarks.self, from: data)
        } catch {
            Log.store.error("Ignoring unreadable Done marks: \(error.localizedDescription, privacy: .public)")
            return DoneMarks()
        }
    }

    func saveDoneMarks() throws {
        defaults.set(try JSONEncoder().encode(doneMarks), forKey: Self.doneMarksKey)
    }
}
