import Foundation

/// Turns decoded habits.json into `Habit` values. Every failure explains what to fix in the file.
enum HabitValidator {
    static let maxDecimals = 3

    static func habits(from document: HabitDocument) throws(ConfigError) -> [Habit] {
        if let key = document.unknownKeys.first {
            throw ConfigError(message: "habits.json: unknown key '\(key)'")
        }
        guard let rawHabits = document.habits else {
            throw ConfigError(message: #"habits.json needs a "habits" list"#)
        }
        var seenIDs: Set<String> = []
        var habits: [Habit] = []
        for (index, raw) in rawHabits.enumerated() {
            let habit = try habit(from: raw, number: index + 1)
            guard seenIDs.insert(habit.id).inserted else {
                throw ConfigError(message: "habit '\(habit.id)': duplicate id")
            }
            habits.append(habit)
        }
        return habits
    }

    private static func habit(from raw: RawHabit, number: Int) throws(ConfigError) -> Habit {
        let label = raw.id.map { "habit '\($0)'" } ?? "habit #\(number)"
        func problem(_ text: String) -> ConfigError {
            ConfigError(message: "\(label): \(text)")
        }

        if let key = raw.unknownKeys.first { throw problem("unknown key '\(key)'") }

        guard let id = raw.id, !id.isEmpty else { throw problem("missing 'id'") }
        guard id.allSatisfy(isIDCharacter) else { throw problem("'id' may only use a–z, 0–9 and _") }
        guard let name = nonBlank(raw.name) else { throw problem("missing 'name'") }

        guard let typeText = raw.type else { throw problem("missing 'type'") }
        guard let type = HabitType(rawValue: typeText) else {
            throw problem("'type' must be binary, count, number or sleep (got '\(typeText)')")
        }
        guard let promptText = raw.prompt else { throw problem("missing 'prompt'") }
        guard let prompt = Prompt(rawValue: promptText) else {
            throw problem("'prompt' must be morning or evening (got '\(promptText)')")
        }
        guard let orderValue = raw.order else { throw problem("missing 'order'") }
        guard let order = Int(exactly: orderValue) else { throw problem("'order' must be a whole number") }

        guard let fromText = raw.activeFrom else { throw problem("missing 'active_from'") }
        guard let activeFrom = Day(fromText) else {
            throw problem("'active_from' must be a date like 2026-10-20 (got '\(fromText)')")
        }
        var activeTo: Day?
        if let toText = raw.activeTo {
            guard let day = Day(toText) else {
                throw problem("'active_to' must be a date like 2026-10-20 (got '\(toText)')")
            }
            guard day >= activeFrom else { throw problem("'active_to' is before 'active_from'") }
            activeTo = day
        }

        var decimals = 0
        if let value = raw.decimals {
            guard type == .number else { throw problem("'decimals' only applies to number habits") }
            guard let whole = Int(exactly: value), (0...maxDecimals).contains(whole) else {
                throw problem("'decimals' must be between 0 and \(maxDecimals)")
            }
            decimals = whole
        }
        if let minTarget = raw.minTarget {
            guard type != .binary else { throw problem("'min_target' doesn't apply to binary habits") }
            guard minTarget > 0 else { throw problem("'min_target' must be greater than 0") }
        }
        if raw.trend == true, type != .number {
            throw problem("'trend' only applies to number habits")
        }

        let tags = raw.tags ?? []
        if !tags.isEmpty {
            guard type == .binary else { throw problem("'tags' only apply to binary habits") }
            guard tags.allSatisfy({ nonBlank($0) != nil && !$0.contains(",") }) else {
                throw problem("tags can't be empty or contain commas")
            }
            if let duplicate = firstDuplicate(in: tags) { throw problem("duplicate tag '\(duplicate)'") }
        }

        return Habit(
            id: id,
            name: name,
            description: nonBlank(raw.description),
            type: type,
            unit: nonBlank(raw.unit),
            decimals: decimals,
            minTarget: raw.minTarget,
            showsTrend: raw.trend ?? false,
            prompt: prompt,
            order: order,
            activeFrom: activeFrom,
            activeTo: activeTo,
            tags: tags
        )
    }

    private static func isIDCharacter(_ character: Character) -> Bool {
        character.isASCII && (character.isLowercase || character.isNumber || character == "_")
    }

    private static func nonBlank(_ text: String?) -> String? {
        guard let trimmed = text?.trimmingCharacters(in: .whitespacesAndNewlines), !trimmed.isEmpty else { return nil }
        return trimmed
    }

    private static func firstDuplicate(in values: [String]) -> String? {
        var seen: Set<String> = []
        return values.first { !seen.insert($0).inserted }
    }
}
