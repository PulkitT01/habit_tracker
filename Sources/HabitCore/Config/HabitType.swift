/// How a habit is logged and what its `value` means.
public enum HabitType: String, Sendable, CaseIterable {
    /// 1 = done, 0 = not done.
    case binary
    /// A whole number of repetitions.
    case count
    /// A measured quantity such as kilograms or seconds.
    case number
    /// Hours slept; the entry's `detail` holds "HH:MM-HH:MM".
    case sleep

    /// Done writes 0 for untouched habits of these types. Number and sleep habits are
    /// measurements, where 0 would be a false reading (0 kg), so they are never auto-filled.
    public var isAutoZeroed: Bool {
        self == .binary || self == .count
    }
}
