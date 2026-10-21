import HabitCore
import SwiftUI

/// A count habit: a number field plus a stepper. ↑/↓ in the field step by one.
///
/// The field edits its own text and saves every valid change. A field bound straight to a number
/// only commits on Return or focus loss, and clicking outside the popover closes it without either.
struct CountRow: View {
    let habit: Habit
    var focus: FocusState<LogFocus?>.Binding
    let onSubmit: () -> Void
    @Environment(HabitStore.self) private var store
    @State private var draft = ""

    var body: some View {
        GridRow {
            RowLabel(habit: habit)
            HStack {
                TextField(habit.name, text: $draft, prompt: Text(verbatim: ""))
                    .labelsHidden()
                    .multilineTextAlignment(.trailing)
                    .frame(width: Design.numberFieldWidth)
                    .invalidOutline(isInvalid)
                    .focused(focus, equals: .habit(habit.id))
                    .onSubmit(onSubmit)
                    .onKeyPress(.upArrow, action: stepUp)
                    .onKeyPress(.downArrow, action: stepDown)
                    .onChange(of: draft, saveDraft)
                    .onChange(of: store.value(of: habit), initial: true) { syncDraft(force: false) }
                    .onChange(of: store.selectedDay) { syncDraft(force: true) }
                Stepper(habit.name, onIncrement: increment, onDecrement: decrement)
                    .labelsHidden()
                UnitLabel(habit: habit)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            StatusGlyph(state: store.dotState(of: habit))
        }
    }

    private var isInvalid: Bool {
        !draft.trimmingCharacters(in: .whitespaces).isEmpty && NumberInput.count(draft) == nil
    }

    private var typedValue: Double? {
        NumberInput.count(draft).map(Double.init)
    }

    /// The stored value as the field displays it.
    private var storedText: String {
        store.value(of: habit).map { HabitFormat.value($0, of: habit) } ?? ""
    }

    private func saveDraft() {
        let change = FieldDraft.change(text: draft, storedText: storedText, storedValue: store.value(of: habit), parsed: typedValue)
        guard case .save(let value) = change else { return }
        store.setCount(habit, to: value.flatMap { Int(exactly: $0) })
    }

    private func syncDraft(force: Bool) {
        guard force || FieldDraft.shouldShowStoredValue(parsed: typedValue, storedValue: store.value(of: habit)) else { return }
        draft = storedText
    }

    private func increment() {
        store.increment(habit)
    }

    private func decrement() {
        store.decrement(habit)
    }

    private func stepUp() -> KeyPress.Result {
        increment()
        return .handled
    }

    private func stepDown() -> KeyPress.Result {
        decrement()
        return .handled
    }
}
