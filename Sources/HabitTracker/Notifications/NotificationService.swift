import Foundation
import HabitCore
import Observation
import UserNotifications

/// Talks to Notification Center: permission, pending requests, delivery, and clicks.
/// Inert when running outside an .app bundle (a bare `swift run`), where the API would crash.
@Observable
final class NotificationService: NSObject {
    private static let threadIdentifier = "reminders"
    /// More names than this are summarized as "and N more".
    private static let maxListedHabits = 5

    private(set) var authorization: UNAuthorizationStatus = .notDetermined
    /// Called on the main actor when a notification is clicked.
    @ObservationIgnored var onOpen: ((OpenedReminder) -> Void)?
    /// Called when notifications become allowed, so reminders can be scheduled right away.
    @ObservationIgnored var onAuthorizationGranted: (() -> Void)?
    @ObservationIgnored private let center: UNUserNotificationCenter?

    override init() {
        center = Bundle.main.bundleIdentifier == nil ? nil : UNUserNotificationCenter.current()
        super.init()
        center?.delegate = self
    }

    var isAvailable: Bool { center != nil }

    // MARK: - Permission

    func requestAuthorization() async {
        guard let center else { return }
        let granted = await withCheckedContinuation { continuation in
            center.requestAuthorization(options: [.alert, .sound]) { @Sendable granted, error in
                if let error {
                    Log.reminders.error("Notification permission request failed: \(error.localizedDescription, privacy: .public)")
                }
                continuation.resume(returning: granted)
            }
        }
        Log.reminders.info("Notifications allowed: \(granted)")
        await refreshAuthorization()
    }

    func refreshAuthorization() async {
        guard let center else { return }
        let previous = authorization
        authorization = await withCheckedContinuation { continuation in
            center.getNotificationSettings { @Sendable settings in
                continuation.resume(returning: settings.authorizationStatus)
            }
        }
        if authorization == .authorized, previous != .authorized {
            onAuthorizationGranted?()
        }
    }

    // MARK: - Requests

    /// Delivery dates of notifications still in Notification Center, by identifier.
    func deliveredDates() async -> [String: Date] {
        guard let center else { return [:] }
        return await withCheckedContinuation { continuation in
            center.getDeliveredNotifications { @Sendable delivered in
                let dates = delivered.map { ($0.request.identifier, $0.date) }
                continuation.resume(returning: Dictionary(dates, uniquingKeysWith: max))
            }
        }
    }

    /// Makes pending requests match `plan`, delivers its immediate notifications, and clears
    /// banners for groups that have since been logged.
    func apply(_ plan: ReminderPlan, today: Day) async {
        guard let center else { return }
        let wanted = Set(plan.scheduled.map(\.id))
        let obsolete = await pendingIdentifiers().filter { !wanted.contains($0) }
        center.removePendingNotificationRequests(withIdentifiers: obsolete)
        let resolved = plan.resolvedPrompts.flatMap { prompt in
            ReminderKind.allCases.map { PlannedNotification.id($0, today, prompt) }
        }
        center.removeDeliveredNotifications(withIdentifiers: resolved)
        for notification in plan.scheduled + plan.immediate {
            await add(notification, to: center)
        }
    }

    /// Before sleep: nothing should fire late on wake; the next plan decides what to send.
    func removeAllPending() {
        center?.removeAllPendingNotificationRequests()
    }

    /// Removes pending and delivered notifications, so a quit Dev build leaves no reminders behind.
    func removeAll() {
        center?.removeAllPendingNotificationRequests()
        center?.removeAllDeliveredNotifications()
    }

    private func pendingIdentifiers() async -> [String] {
        guard let center else { return [] }
        return await withCheckedContinuation { continuation in
            center.getPendingNotificationRequests { @Sendable requests in
                continuation.resume(returning: requests.map(\.identifier))
            }
        }
    }

    private func add(_ notification: PlannedNotification, to center: UNUserNotificationCenter) async {
        let request = Self.request(for: notification)
        await withCheckedContinuation { continuation in
            center.add(request) { @Sendable error in
                if let error {
                    Log.reminders.error("Couldn't schedule \(notification.id, privacy: .public): \(error.localizedDescription, privacy: .public)")
                }
                continuation.resume()
            }
        }
    }

    // MARK: - Content

    private static func request(for notification: PlannedNotification) -> UNNotificationRequest {
        let content = UNMutableNotificationContent()
        content.title = title(for: notification)
        content.body = body(for: notification)
        content.sound = .default
        content.threadIdentifier = threadIdentifier
        content.userInfo = ["day": notification.day.iso, "prompt": notification.prompt.rawValue, "kind": notification.kind.rawValue]
        let trigger = notification.fireDate.map { date in
            UNCalendarNotificationTrigger(
                dateMatching: Calendar.current.dateComponents([.year, .month, .day, .hour, .minute, .second], from: date),
                repeats: false
            )
        }
        return UNNotificationRequest(identifier: notification.id, content: content, trigger: trigger)
    }

    private static func title(for notification: PlannedNotification) -> String {
        switch (notification.kind, notification.prompt) {
        case (.reminder, .morning), (.catchUp, .morning): String(localized: "Morning check-in")
        case (.reminder, .evening), (.catchUp, .evening): String(localized: "Evening check-in")
        case (.followUp, .morning): String(localized: "Morning habits still to log")
        case (.followUp, .evening): String(localized: "Evening habits still to log")
        }
    }

    private static func body(for notification: PlannedNotification) -> String {
        let names = notification.habitNames
        guard names.count > maxListedHabits else { return names.formatted(.list(type: .and)) }
        let listed = names.prefix(maxListedHabits - 1)
        return (listed + [String(localized: "\(names.count - listed.count) more")]).formatted(.list(type: .and))
    }
}

extension NotificationService: UNUserNotificationCenterDelegate {
    /// Show banners even while the popover (and so the app) is active.
    nonisolated func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification,
        withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void
    ) {
        completionHandler([.banner, .list, .sound])
    }

    nonisolated func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        didReceive response: UNNotificationResponse,
        withCompletionHandler completionHandler: @escaping () -> Void
    ) {
        let isClick = response.actionIdentifier == UNNotificationDefaultActionIdentifier
        let info = response.notification.request.content.userInfo
        let opened = OpenedReminder(
            day: (info["day"] as? String).flatMap(Day.init),
            prompt: (info["prompt"] as? String).flatMap(Prompt.init(rawValue:)),
            kind: (info["kind"] as? String).flatMap(ReminderKind.init(rawValue:)),
            deliveredAt: response.notification.date
        )
        completionHandler()
        guard isClick else { return }
        Task { @MainActor in
            self.onOpen?(opened)
        }
    }
}
