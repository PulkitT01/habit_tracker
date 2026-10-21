import Foundation
import HabitCore

/// Keeps notifications in line with what's logged. Replans are coalesced; one more runs just
/// after each scheduled notification fires, so the planner learns what was shown.
final class ReminderController {
    private static let logKey = "reminderLog"
    private static let replanDelay: Duration = .seconds(1)
    /// Gives macOS a moment to deliver anything it held during sleep before we look.
    private static let wakeDelay: Duration = .seconds(5)
    private static let checkMargin: TimeInterval = 2

    private let store: HabitStore
    private let settings: AppSettings
    private let notifications: NotificationService
    private let defaults: UserDefaults
    private var awakeSince = Date.now
    private var replanTask: Task<Void, Never>?
    private var checkTask: Task<Void, Never>?

    init(store: HabitStore, settings: AppSettings, notifications: NotificationService, defaults: UserDefaults = .standard) {
        self.store = store
        self.settings = settings
        self.notifications = notifications
        self.defaults = defaults
    }

    func start() {
        guard notifications.isAvailable else {
            Log.reminders.notice("Not running from an app bundle; reminders are off")
            return
        }
        Task {
            await notifications.requestAuthorization()
            requestReplan(after: Self.wakeDelay)
        }
    }

    func requestReplan(after delay: Duration = replanDelay) {
        replanTask?.cancel()
        replanTask = Task { [weak self] in
            do {
                try await Task.sleep(for: delay)
            } catch {
                return // superseded by a newer request
            }
            await self?.replan()
        }
    }

    /// A clicked notification was certainly seen, even though the click removed it from
    /// Notification Center (and may have relaunched the app with no memory of it).
    func recordShown(_ opened: OpenedReminder) {
        guard let day = opened.day, let prompt = opened.prompt, let kind = opened.kind else { return }
        saveLog(loadLog().markingShown(kind, day: day, prompt: prompt, at: opened.deliveredAt))
        requestReplan()
    }

    func systemWillSleep() {
        replanTask?.cancel()
        checkTask?.cancel()
        notifications.removeAllPending()
    }

    func systemDidWake() {
        awakeSince = .now
        requestReplan(after: Self.wakeDelay)
    }

    private func replan() async {
        guard notifications.isAvailable else { return }
        // A habits.json that failed to load at launch leaves no habits; keep what's pending
        // instead of cancelling every reminder until the file is fixed.
        guard store.configError == nil || !store.config.habits.isEmpty else { return }
        let delivered = await notifications.deliveredDates()
        let now = Date.now
        let planner = ReminderPlanner(boundary: DayBoundary(timeZone: .autoupdatingCurrent), settings: settings.reminderSettings)
        let plan = planner.plan(
            now: now,
            today: store.today,
            groups: store.todayReminderGroups,
            tomorrowGroups: store.tomorrowReminderGroups,
            log: loadLog(),
            delivered: delivered,
            awakeSince: awakeSince
        )
        saveLog(plan.log)
        await notifications.apply(plan, today: store.today)
        scheduleCheck(for: plan, now: now)
        Log.reminders.debug("Planned \(plan.scheduled.count) reminders, sent \(plan.immediate.count) now")
    }

    private func scheduleCheck(for plan: ReminderPlan, now: Date) {
        checkTask?.cancel()
        guard let next = plan.scheduled.compactMap(\.fireDate).filter({ $0 > now }).min() else { return }
        let delay = next.timeIntervalSince(now) + Self.checkMargin
        checkTask = Task { [weak self] in
            do {
                try await Task.sleep(for: .seconds(delay))
            } catch {
                return // replaced by a newer plan
            }
            self?.requestReplan(after: .zero)
        }
    }

    private func loadLog() -> ReminderLog {
        guard let data = defaults.data(forKey: Self.logKey) else { return ReminderLog() }
        do {
            return try JSONDecoder().decode(ReminderLog.self, from: data)
        } catch {
            Log.reminders.error("Ignoring unreadable reminder log: \(error.localizedDescription, privacy: .public)")
            return ReminderLog()
        }
    }

    private func saveLog(_ log: ReminderLog) {
        do {
            defaults.set(try JSONEncoder().encode(log), forKey: Self.logKey)
        } catch {
            Log.reminders.error("Couldn't save the reminder log: \(error.localizedDescription, privacy: .public)")
        }
    }
}
