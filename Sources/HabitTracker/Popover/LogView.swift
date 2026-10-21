import HabitCore
import SwiftUI

/// The day being logged: day switcher, banners, Morning and Evening habits, note, Done.
struct LogView: View {
    @Environment(HabitStore.self) private var store
    @FocusState private var focus: LogFocus?

    var body: some View {
        VStack(spacing: 0) {
            ScrollView {
                VStack(alignment: .leading, spacing: Design.sectionSpacing) {
                    DaySwitcher()
                    if let message = store.configError {
                        ErrorBanner(message: message)
                    }
                    if let message = store.errorMessage {
                        ErrorBanner(message: message, dismiss: dismissError)
                    }
                    if store.showsYesterdayBanner {
                        YesterdayBanner()
                    }
                    Grid(alignment: .leading, horizontalSpacing: Design.gridColumnSpacing, verticalSpacing: Design.gridRowSpacing) {
                        ForEach(promptsWithHabits) { prompt in
                            HabitSection(
                                prompt: prompt,
                                isFirst: prompt == promptsWithHabits.first,
                                focus: $focus,
                                advanceFocus: advanceFocus
                            )
                        }
                    }
                    if promptsWithHabits.isEmpty {
                        ContentUnavailableView("No Habits Today", systemImage: "list.bullet", description: Text("Add habits in habits.json from the gear menu."))
                    }
                    DayNoteField(focus: $focus)
                }
                .padding()
            }
            Divider()
            DoneBar()
                .padding()
        }
        // Start on the first unlogged habit each time the popover opens or the day changes.
        .task(id: store.isPopoverPresented) { focus = firstUnlogged }
        .onChange(of: store.selectedDay) { focus = firstUnlogged }
    }

    private var promptsWithHabits: [Prompt] {
        Prompt.allCases.filter { !store.habits(for: $0).isEmpty }
    }

    /// Fields in Tab order; ↩ in a field moves to the next one.
    private var focusOrder: [LogFocus] {
        let habits = promptsWithHabits.flatMap { store.habits(for: $0) }
        let fields = habits.flatMap { habit -> [LogFocus] in
            habit.type == .sleep ? [.habit(habit.id), .wake(habit.id)] : [.habit(habit.id)]
        }
        return fields + [.note]
    }

    private var firstUnlogged: LogFocus? {
        promptsWithHabits
            .flatMap { store.habits(for: $0) }
            .first { store.value(of: $0) == nil }
            .map { .habit($0.id) }
    }

    private func advanceFocus(from current: LogFocus) {
        focus = LogFocus.next(after: current, in: focusOrder)
    }

    private func dismissError() {
        store.errorMessage = nil
    }
}
