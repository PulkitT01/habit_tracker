import SwiftUI

/// The MenuBarExtra window: tab bar and the selected tab, in one fixed-size frame.
struct PopoverView: View {
    @Environment(HabitStore.self) private var store

    var body: some View {
        @Bindable var store = store
        VStack(spacing: 0) {
            TabBar(selection: $store.selectedTab)
                .padding()
            Divider()
            if let message = store.startupError {
                ContentUnavailableView("Database Unavailable", systemImage: "externaldrive.badge.exclamationmark", description: Text(message))
            } else {
                switch store.selectedTab {
                case .log:
                    LogView()
                case .stats:
                    StatsView()
                case .settings:
                    SettingsView()
                }
            }
        }
        .frame(width: Design.popoverWidth, height: Design.popoverHeight, alignment: .top)
    }
}
