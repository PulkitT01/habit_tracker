/// Formats a non-negative integer with leading zeros, independent of locale ("7" → "07").
/// Used for the fixed storage formats `YYYY-MM-DD` and `HH:MM`.
func zeroPadded(_ value: Int, width: Int) -> String {
    let digits = String(value)
    return String(repeating: "0", count: max(0, width - digits.count)) + digits
}
