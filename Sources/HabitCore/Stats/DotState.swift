/// One habit on one day, as shown in the 7-day dot strip.
public enum DotState: Sendable, Equatable {
    case done
    /// Logged, but 0 or below the minimum target.
    case missed
    /// Active but no value: not logged, never "not done".
    case notLogged
    /// Before `active_from` or after `active_to`.
    case inactive

    public init(habit: Habit, day: Day, value: Double?) {
        if !habit.isActive(on: day) {
            self = .inactive
        } else if let value {
            self = habit.isDone(value) ? .done : .missed
        } else {
            self = .notLogged
        }
    }
}
