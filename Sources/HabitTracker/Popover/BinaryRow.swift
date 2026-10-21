import HabitCore
import SwiftUI

/// A checkbox habit, with tag chips when the habit has tags.
struct BinaryRow: View {
    let habit: Habit
    var focus: FocusState<LogFocus?>.Binding
    @Environment(HabitStore.self) private var store

    var body: some View {
        @Bindable var store = store
        GridRow {
            RowLabel(habit: habit)
            HStack {
                KeyToggle(title: habit.name, isOn: $store[isDone: habit], onClear: clear)
                    .focused(focus, equals: .habit(habit.id))
                ForEach(habit.tags, id: \.self) { tag in
                    TagChip(tag: tag, isSelected: $store[tag: tag, of: habit])
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            StatusGlyph(state: store.dotState(of: habit))
        }
    }

    private func clear() {
        store.clear(habit)
    }
}
