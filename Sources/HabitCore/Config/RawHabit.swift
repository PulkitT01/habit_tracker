/// One habit exactly as written in habits.json. Every field is optional so `HabitValidator`
/// can report missing or invalid values in plain words instead of decoder jargon.
/// Whole-number fields decode as `Double` so "order": 1.5 gets a clear message too.
struct RawHabit: Decodable {
    let id: String?
    let name: String?
    let description: String?
    let type: String?
    let unit: String?
    let decimals: Double?
    let minTarget: Double?
    let trend: Bool?
    let prompt: String?
    let order: Double?
    let activeFrom: String?
    let activeTo: String?
    let tags: [String]?
    /// Keys that aren't part of the format, usually typos such as "min_targt".
    let unknownKeys: [String]

    enum CodingKeys: String, CodingKey {
        case id, name, description, type, unit, decimals
        case minTarget = "min_target"
        case trend, prompt, order
        case activeFrom = "active_from"
        case activeTo = "active_to"
        case tags
    }

    init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decodeIfPresent(String.self, forKey: .id)
        name = try container.decodeIfPresent(String.self, forKey: .name)
        description = try container.decodeIfPresent(String.self, forKey: .description)
        type = try container.decodeIfPresent(String.self, forKey: .type)
        unit = try container.decodeIfPresent(String.self, forKey: .unit)
        decimals = try container.decodeIfPresent(Double.self, forKey: .decimals)
        minTarget = try container.decodeIfPresent(Double.self, forKey: .minTarget)
        trend = try container.decodeIfPresent(Bool.self, forKey: .trend)
        prompt = try container.decodeIfPresent(String.self, forKey: .prompt)
        order = try container.decodeIfPresent(Double.self, forKey: .order)
        activeFrom = try container.decodeIfPresent(String.self, forKey: .activeFrom)
        activeTo = try container.decodeIfPresent(String.self, forKey: .activeTo)
        tags = try container.decodeIfPresent([String].self, forKey: .tags)
        unknownKeys = try AnyCodingKey.unknownKeys(in: decoder, allowed: CodingKeys.self)
    }
}
