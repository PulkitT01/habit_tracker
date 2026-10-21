/// Groups finished with the Done button, per day. This is app state kept in UserDefaults,
/// not analysis data: the database only ever holds what you logged.
public struct DoneMarks: Sendable, Equatable, Codable {
    public static let retentionDays = 60

    /// Day (`YYYY-MM-DD`) → prompt raw values; plain strings keep the JSON readable.
    private let marks: [String: Set<String>]

    public init() {
        marks = [:]
    }

    private init(marks: [String: Set<String>]) {
        self.marks = marks
    }

    public func prompts(on day: Day) -> Set<Prompt> {
        Set((marks[day.iso] ?? []).compactMap(Prompt.init(rawValue:)))
    }

    public func marking(_ prompts: Set<Prompt>, on day: Day) -> DoneMarks {
        var updated = marks
        updated[day.iso, default: []].formUnion(prompts.map(\.rawValue))
        return DoneMarks(marks: updated)
    }

    /// Drops marks for days before `day`.
    public func pruned(before day: Day) -> DoneMarks {
        DoneMarks(marks: marks.filter { Day($0.key).map { $0 >= day } ?? false })
    }
}
