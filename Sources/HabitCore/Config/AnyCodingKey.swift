/// A coding key that matches any JSON key, used to find keys a format doesn't define.
struct AnyCodingKey: CodingKey {
    let stringValue: String
    var intValue: Int? { nil }

    init(stringValue: String) {
        self.stringValue = stringValue
    }

    init?(intValue: Int) {
        nil
    }

    /// The object's keys that `Allowed` doesn't define, sorted.
    static func unknownKeys<Allowed: CodingKey>(in decoder: any Decoder, allowed: Allowed.Type) throws -> [String] {
        try decoder.container(keyedBy: AnyCodingKey.self).allKeys
            .map(\.stringValue)
            .filter { Allowed(stringValue: $0) == nil }
            .sorted()
    }
}
