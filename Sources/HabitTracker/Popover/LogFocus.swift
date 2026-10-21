/// Focusable fields in the Log tab, in Tab order.
enum LogFocus: Hashable {
    /// A habit's main control (field, checkbox, or bedtime picker).
    case habit(String)
    /// The wake-time picker of a sleep habit.
    case wake(String)
    case note

    /// The field after `current`, for moving on with ↩.
    static func next(after current: LogFocus, in order: [LogFocus]) -> LogFocus? {
        guard let index = order.firstIndex(of: current), order.indices.contains(index + 1) else { return nil }
        return order[index + 1]
    }
}
