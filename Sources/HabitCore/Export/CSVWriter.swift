/// Minimal RFC 4180-style CSV: fields are quoted only when they contain a comma, quote or line
/// break; quotes are doubled; nil is an empty field (pandas reads it as NaN).
public enum CSVWriter {
    public static func field(_ value: String?) -> String {
        guard let value else { return "" }
        let needsQuotes = value.contains { $0 == "," || $0 == "\"" || $0.isNewline }
        return needsQuotes ? "\"\(value.replacing("\"", with: "\"\""))\"" : value
    }

    public static func line(_ fields: [String?]) -> String {
        fields.map(field).joined(separator: ",")
    }

    /// Header plus rows, each line ending in "\n".
    public static func document(header: [String], rows: [[String?]]) -> String {
        ([line(header)] + rows.map(line)).map { $0 + "\n" }.joined()
    }
}
