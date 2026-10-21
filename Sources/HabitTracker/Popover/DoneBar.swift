import SwiftUI

/// The Done button (⌘↩): marks untouched toggles and counts as not done and closes the popover.
struct DoneBar: View {
    @Environment(HabitStore.self) private var store

    var body: some View {
        HStack {
            Text("Untouched checkboxes and counts are saved as not done.")
                .font(.caption)
                .foregroundStyle(.secondary)
            Spacer()
            Button("Done", action: finish)
                .keyboardShortcut(.return, modifiers: .command)
                .buttonStyle(.borderedProminent)
                .help("Finish this day (⌘↩)")
        }
    }

    private func finish() {
        store.done()
    }
}
