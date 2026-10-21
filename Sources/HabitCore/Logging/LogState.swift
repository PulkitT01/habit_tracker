/// How completely a prompt group, or a whole day, is logged.
public enum LogState: Sendable, Equatable {
    /// No habit is active, so there is nothing to log.
    case notApplicable
    /// Nothing logged and Done not pressed.
    case empty
    /// Some habits logged.
    case partial
    /// Every habit has a value, or Done was pressed.
    case logged
}
