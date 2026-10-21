/// The reminder group a habit belongs to. Cases are in display order.
public enum Prompt: String, Sendable, CaseIterable, Comparable, Identifiable {
    case morning
    case evening

    public var id: Self { self }

    public static func < (lhs: Prompt, rhs: Prompt) -> Bool {
        lhs.sortIndex < rhs.sortIndex
    }

    private var sortIndex: Int {
        switch self {
        case .morning: 0
        case .evening: 1
        }
    }
}
