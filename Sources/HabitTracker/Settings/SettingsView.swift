import SwiftUI

/// Reminder times, launch at login, notification permission and data export.
struct SettingsView: View {
    @Environment(AppSettings.self) private var settings
    @Environment(HabitStore.self) private var store

    var body: some View {
        @Bindable var settings = settings
        Form {
            Section("Reminders") {
                DatePicker("Morning", selection: $settings.morningReminderDate, displayedComponents: .hourAndMinute)
                DatePicker("Evening", selection: $settings.eveningReminderDate, displayedComponents: .hourAndMinute)
                Stepper(value: $settings.followUpMinutes, in: AppSettings.followUpRange, step: 5) {
                    Text("Follow-up after \(settings.followUpMinutes) min if still unlogged")
                }
                NotificationStatusRow()
            }
            Section("General") {
                LoginItemRow()
            }
            Section("Data") {
                ExportRow()
                LabeledContent("Data folder") {
                    Button("Show in Finder", action: showDataFolder)
                }
            }
        }
        .formStyle(.grouped)
    }

    private func showDataFolder() {
        NSWorkspace.shared.activateFileViewerSelecting([store.paths.database])
    }
}
