import SwiftUI
import UserNotifications

/// Whether reminders can show, with a way to fix it when they can't.
struct NotificationStatusRow: View {
    @Environment(NotificationService.self) private var notifications

    var body: some View {
        LabeledContent("Notifications") {
            switch notifications.authorization {
            case .authorized, .provisional:
                Text("On")
            case .denied:
                Button("Turn On in System Settings…", action: openSystemSettings)
            case .notDetermined:
                Button("Allow…", action: requestPermission)
            @unknown default:
                Button("Check in System Settings…", action: openSystemSettings)
            }
        }
        .task { await notifications.refreshAuthorization() }
    }

    private func requestPermission() {
        Task { await notifications.requestAuthorization() }
    }

    private func openSystemSettings() {
        let identifier = Bundle.main.bundleIdentifier ?? ""
        guard let url = URL(string: "x-apple.systempreferences:com.apple.Notifications-Settings.extension?id=\(identifier)") else { return }
        NSWorkspace.shared.open(url)
    }
}
