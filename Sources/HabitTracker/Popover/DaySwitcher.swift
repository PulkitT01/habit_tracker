import SwiftUI

/// ‹ [Today | Yesterday] [date] ›, with ⌘[ and ⌘] for the previous and next day.
struct DaySwitcher: View {
    @Environment(HabitStore.self) private var store

    var body: some View {
        @Bindable var store = store
        HStack {
            Button("Previous Day", systemImage: "chevron.left", action: store.selectPreviousDay)
                .labelStyle(.iconOnly)
                .keyboardShortcut("[", modifiers: .command)
                .help("Previous day (⌘[)")
            Picker("Day", selection: $store.dayChoice) {
                Text("Today").tag(DayChoice.today)
                Text("Yesterday").tag(DayChoice.yesterday)
            }
            .pickerStyle(.segmented)
            .labelsHidden()
            .fixedSize()
            DatePicker("Date", selection: $store.selectedDate, in: ...store.latestSelectableDate, displayedComponents: .date)
                .labelsHidden()
                .datePickerStyle(.field)
            Button("Next Day", systemImage: "chevron.right", action: store.selectNextDay)
                .labelStyle(.iconOnly)
                .keyboardShortcut("]", modifiers: .command)
                .help("Next day (⌘])")
                .disabled(!store.canSelectNextDay)
        }
        .buttonStyle(.borderless)
    }
}
