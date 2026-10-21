/// One habit from habits.json. `id` is the stable key stored in the database.
public struct Habit: Identifiable, Hashable, Sendable {
    public let id: String
    public let name: String
    /// Definitions shown as a tooltip, e.g. "girlfriend doesn't count".
    public let description: String?
    public let type: HabitType
    public let unit: String?
    /// Fraction digits for number habits (weight uses 1).
    public let decimals: Int
    /// Lowest value that counts as done for count, number and sleep habits.
    public let minTarget: Double?
    /// Number habits only: show an EWMA trend and weekly rate of change.
    public let showsTrend: Bool
    public let prompt: Prompt
    public let order: Int
    /// First day the habit is tracked; earlier days are inactive, never "missing".
    public let activeFrom: Day
    /// Last tracked day (inclusive), for retired habits.
    public let activeTo: Day?
    /// Optional choices stored in an entry's `detail` (binary habits only).
    public let tags: [String]

    public init(
        id: String,
        name: String,
        description: String? = nil,
        type: HabitType,
        unit: String? = nil,
        decimals: Int = 0,
        minTarget: Double? = nil,
        showsTrend: Bool = false,
        prompt: Prompt,
        order: Int,
        activeFrom: Day,
        activeTo: Day? = nil,
        tags: [String] = []
    ) {
        self.id = id
        self.name = name
        self.description = description
        self.type = type
        self.unit = unit
        self.decimals = decimals
        self.minTarget = minTarget
        self.showsTrend = showsTrend
        self.prompt = prompt
        self.order = order
        self.activeFrom = activeFrom
        self.activeTo = activeTo
        self.tags = tags
    }

    public func isActive(on day: Day) -> Bool {
        day >= activeFrom && activeTo.map { day <= $0 } ?? true
    }

    /// Whether a logged value counts as done. Binary needs 1; other types need `minTarget`
    /// when set, otherwise any value above 0.
    public func isDone(_ value: Double) -> Bool {
        switch type {
        case .binary:
            value >= 1
        case .count, .number, .sleep:
            if let minTarget { value >= minTarget } else { value > 0 }
        }
    }
}
