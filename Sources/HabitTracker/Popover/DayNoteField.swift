import SwiftUI

/// An optional note for the day ("sick", "travelling"), saved as you type.
struct DayNoteField: View {
    var focus: FocusState<LogFocus?>.Binding
    @Environment(HabitStore.self) private var store
    @State private var draft = ""

    var body: some View {
        TextField("Note", text: $draft, prompt: Text("Note for the day (sick, travelling…)"))
            .labelsHidden()
            .focused(focus, equals: .note)
            .onChange(of: draft, saveDraft)
            .onChange(of: store.note, initial: true, syncDraft)
    }

    private func saveDraft() {
        guard draft != store.note else { return }
        store.setNote(draft)
    }

    private func syncDraft() {
        if draft != store.note {
            draft = store.note
        }
    }
}
