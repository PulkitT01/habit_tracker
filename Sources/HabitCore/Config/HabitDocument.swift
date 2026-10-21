/// The top level of habits.json: `{"habits": [...]}`.
struct HabitDocument: Decodable {
    let habits: [RawHabit]?
    let unknownKeys: [String]

    enum CodingKeys: String, CodingKey {
        case habits
    }

    init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        habits = try container.decodeIfPresent([RawHabit].self, forKey: .habits)
        unknownKeys = try AnyCodingKey.unknownKeys(in: decoder, allowed: CodingKeys.self)
    }
}
