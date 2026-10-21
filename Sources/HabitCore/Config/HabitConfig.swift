import Foundation

/// The validated contents of habits.json, sorted for display (morning first, then `order`, then id).
public struct HabitConfig: Sendable, Equatable {
    public static let fileName = "habits.json"
    public static let empty = HabitConfig(habits: [])

    public let habits: [Habit]

    public init(habits: [Habit]) {
        self.habits = habits.sorted { ($0.prompt, $0.order, $0.id) < ($1.prompt, $1.order, $1.id) }
    }

    public static func load(from url: URL) throws(ConfigError) -> HabitConfig {
        try parse(data(at: url))
    }

    /// The raw file, with readable errors for a missing or unreadable file.
    public static func data(at url: URL) throws(ConfigError) -> Data {
        do {
            return try Data(contentsOf: url)
        } catch CocoaError.fileReadNoSuchFile {
            throw ConfigError(message: "habits.json not found at \(url.path(percentEncoded: false))")
        } catch {
            throw ConfigError(message: "habits.json couldn't be read: \(error.localizedDescription)")
        }
    }

    public static func parse(_ data: Data) throws(ConfigError) -> HabitConfig {
        let document: HabitDocument
        do {
            document = try JSONDecoder().decode(HabitDocument.self, from: data)
        } catch let error as DecodingError {
            throw ConfigError(message: describe(error))
        } catch {
            throw ConfigError(message: "habits.json couldn't be read: \(error.localizedDescription)")
        }
        return HabitConfig(habits: try HabitValidator.habits(from: document))
    }

    public func habit(id: String) -> Habit? {
        habits.first { $0.id == id }
    }

    public func habits(activeOn day: Day) -> [Habit] {
        habits.filter { $0.isActive(on: day) }
    }

    public func habits(activeOn day: Day, prompt: Prompt) -> [Habit] {
        habits.filter { $0.prompt == prompt && $0.isActive(on: day) }
    }

    // MARK: - Decoding errors

    private static func describe(_ error: DecodingError) -> String {
        switch error {
        case let .typeMismatch(type, context), let .valueNotFound(type, context):
            "\(path(of: context.codingPath)): expected \(describe(type))"
        case let .keyNotFound(key, context):
            "\(path(of: context.codingPath + [key])): missing"
        case let .dataCorrupted(context) where context.codingPath.isEmpty:
            "habits.json isn't valid JSON: \(details(of: context))"
        case let .dataCorrupted(context):
            "\(path(of: context.codingPath)): \(details(of: context))"
        @unknown default:
            "habits.json couldn't be read: \(error.localizedDescription)"
        }
    }

    /// A JSON path such as `habits[2].order`.
    private static func path(of codingPath: [any CodingKey]) -> String {
        codingPath.enumerated().map { index, key in
            if let position = key.intValue {
                "[\(position)]"
            } else if index == 0 {
                key.stringValue
            } else {
                ".\(key.stringValue)"
            }
        }
        .joined()
    }

    private static func describe(_ type: Any.Type) -> String {
        switch type {
        case is Int.Type: "a whole number"
        case is Double.Type: "a number"
        case is String.Type: "text"
        case is Bool.Type: "true or false"
        case is [String].Type: "a list of text"
        case is [RawHabit].Type: "a list of habits"
        default: "\(type)"
        }
    }

    private static func details(of context: DecodingError.Context) -> String {
        guard let underlying = context.underlyingError else { return context.debugDescription }
        let error = underlying as NSError
        return error.userInfo[NSDebugDescriptionErrorKey] as? String ?? error.localizedDescription
    }
}
