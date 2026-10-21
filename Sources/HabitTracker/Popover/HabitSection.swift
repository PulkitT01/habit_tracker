import HabitCore
import SwiftUI

/// "Morning" or "Evening" and its habits, as rows of the Log tab's shared grid so that controls
/// line up across sections.
struct HabitSection: View {
    let prompt: Prompt
    let isFirst: Bool
    var focus: FocusState<LogFocus?>.Binding
    let advanceFocus: (LogFocus) -> Void
    @Environment(HabitStore.self) private var store

    var body: some View {
        let habits = store.habits(for: prompt)
        GridRow {
            SectionHeader(
                prompt: prompt,
                loggedCount: habits.count { store.value(of: $0) != nil },
                totalCount: habits.count,
                isMarkedDone: store.doneMarks.prompts(on: store.selectedDay).contains(prompt)
            )
            .padding(.top, isFirst ? 0 : Design.sectionSpacing)
            .gridCellColumns(3)
        }
        ForEach(habits) { habit in
            HabitRow(habit: habit, focus: focus) {
                advanceFocus(.habit(habit.id))
            }
        }
    }
}
