import SwiftUI

/// Shown on Today when yesterday isn't finished; one click switches to it.
struct YesterdayBanner: View {
    @Environment(HabitStore.self) private var store

    var body: some View {
        HStack {
            Label("Yesterday isn't fully logged", systemImage: "calendar.badge.exclamationmark")
            Spacer()
            Button("Log Yesterday", action: logYesterday)
        }
        .padding(Design.chipHorizontalPadding)
        .background(.orange.quinary, in: .rect(cornerRadius: Design.cornerRadius))
    }

    private func logYesterday() {
        store.select(store.today.adding(days: -1))
    }
}
