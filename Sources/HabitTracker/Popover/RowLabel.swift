import HabitCore
import SwiftUI

/// A habit's name, with its description as a tooltip and "Clear Entry" on right-click.
struct RowLabel: View {
    let habit: Habit
    @Environment(HabitStore.self) private var store

    var body: some View {
        Text(habit.name)
            .lineLimit(1)
            .help(habit.description ?? "")
            .contextMenu {
                Button("Clear Entry", systemImage: "eraser", action: clear)
            }
    }

    private func clear() {
        store.clear(habit)
    }
}
