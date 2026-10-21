import HabitCore
import SwiftUI

/// A measured number such as weight or seconds, rounded to the habit's decimals.
/// The placeholder shows the previous logged value. Like `CountRow`, the field saves every valid edit.
struct NumberRow: View {
    let habit: Habit
    var focus: FocusState<LogFocus?>.Binding
    let onSubmit: () -> Void
    @Environment(HabitStore.self) private var store
    @State private var draft = ""

    var body: some View {
        GridRow {
            RowLabel(habit: habit)
            HStack {
                TextField(habit.name, text: $draft, prompt: Text(verbatim: placeholder))
                    .labelsHidden()
                    .multilineTextAlignment(.trailing)
                    .frame(width: Design.numberFieldWidth)
                    .invalidOutline(isInvalid)
                    .focused(focus, equals: .habit(habit.id))
                    .onSubmit(onSubmit)
                    .onChange(of: draft, saveDraft)
                    .onChange(of: store.value(of: habit), initial: true) { syncDraft(force: false) }
                    .onChange(of: store.selectedDay) { syncDraft(force: true) }
                UnitLabel(habit: habit)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            StatusGlyph(state: store.dotState(of: habit))
        }
    }

    private var placeholder: String {
        store.previousValue(of: habit).map { HabitFormat.value($0, of: habit) } ?? ""
    }

    private var isInvalid: Bool {
        !draft.trimmingCharacters(in: .whitespaces).isEmpty && typedValue == nil
    }

    /// The typed number; more decimals than the habit stores counts as invalid, never rounded.
    private var typedValue: Double? {
        NumberInput.decimal(draft, maxFractionDigits: habit.decimals)
    }

    /// The stored value as the field displays it.
    private var storedText: String {
        store.value(of: habit).map { HabitFormat.value($0, of: habit) } ?? ""
    }

    private func saveDraft() {
        let change = FieldDraft.change(text: draft, storedText: storedText, storedValue: store.value(of: habit), parsed: typedValue)
        guard case .save(let value) = change else { return }
        store.setNumber(habit, to: value)
    }

    private func syncDraft(force: Bool) {
        guard force || FieldDraft.shouldShowStoredValue(parsed: typedValue, storedValue: store.value(of: habit)) else { return }
        draft = storedText
    }
}
