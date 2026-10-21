import HabitCore
import SwiftUI

/// Bedtime → wake time. Until sleep is logged the pickers show the previous night's times;
/// changing either logs the night, and ✓ logs the suggestion unchanged.
struct SleepRow: View {
    let habit: Habit
    var focus: FocusState<LogFocus?>.Binding
    @Environment(HabitStore.self) private var store

    var body: some View {
        @Bindable var store = store
        GridRow {
            RowLabel(habit: habit)
            HStack {
                DatePicker("Bedtime", selection: $store[bedtimeOf: habit], displayedComponents: .hourAndMinute)
                    .labelsHidden()
                    .datePickerStyle(.field)
                    .focused(focus, equals: .habit(habit.id))
                Image(systemName: "arrow.right")
                    .foregroundStyle(.secondary)
                    .accessibilityHidden(true)
                DatePicker("Wake time", selection: $store[wakeOf: habit], displayedComponents: .hourAndMinute)
                    .labelsHidden()
                    .datePickerStyle(.field)
                    .focused(focus, equals: .wake(habit.id))
                Text(HabitFormat.hours(hours))
                    .monospacedDigit()
                    .foregroundStyle(isLogged ? .primary : .tertiary)
                Button("Log Sleep", systemImage: "checkmark", action: logSuggestion)
                    .labelStyle(.iconOnly)
                    .buttonStyle(.borderless)
                    .help("Log these times")
                    .opacity(isLogged ? 0 : 1)
                    .disabled(isLogged)
                    .accessibilityHidden(isLogged)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            StatusGlyph(state: store.dotState(of: habit))
        }
    }

    private var isLogged: Bool {
        store.value(of: habit) != nil
    }

    /// The logged hours, or the suggestion's duration.
    private var hours: Double {
        store.value(of: habit) ?? store.sleepLog(for: habit).hours(wakeDay: store.selectedDay, timeZone: .autoupdatingCurrent)
    }

    private func logSuggestion() {
        store.setSleep(habit, to: store.sleepLog(for: habit))
    }
}
