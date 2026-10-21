import SwiftUI

/// The status-bar icon: an empty circle, a half-filled circle, or a check for today.
struct MenuBarIcon: View {
    @Environment(HabitStore.self) private var store

    var body: some View {
        Image(systemName: store.menuBarSymbol)
            .accessibilityLabel("HabitTracker, \(store.todayStatus.loggedHabitCount) of \(store.todayStatus.activeHabitCount) habits logged today")
    }
}
