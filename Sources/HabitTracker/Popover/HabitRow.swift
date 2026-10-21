import HabitCore
import SwiftUI

/// Picks the row for a habit's type. Each row is a `GridRow` of label, controls and status.
struct HabitRow: View {
    let habit: Habit
    var focus: FocusState<LogFocus?>.Binding
    let onSubmit: () -> Void

    var body: some View {
        switch habit.type {
        case .binary:
            BinaryRow(habit: habit, focus: focus)
        case .count:
            CountRow(habit: habit, focus: focus, onSubmit: onSubmit)
        case .number:
            NumberRow(habit: habit, focus: focus, onSubmit: onSubmit)
        case .sleep:
            SleepRow(habit: habit, focus: focus)
        }
    }
}
