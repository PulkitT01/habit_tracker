import HabitCore
import SwiftUI

/// "reps · ≥5", "kg", or nothing.
struct UnitLabel: View {
    let habit: Habit

    var body: some View {
        Text([habit.unit, HabitFormat.target(of: habit)].compactMap(\.self).joined(separator: " · "))
            .foregroundStyle(.secondary)
            .lineLimit(1)
    }
}
