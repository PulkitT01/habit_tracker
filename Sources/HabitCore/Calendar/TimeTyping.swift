/// When a part typed into a time field is finished, so the field can move on: after two digits
/// ("08"), or after one that no value continues ("9" as an hour, "7" as minutes).
public enum TimeTyping {
    public static func isHourComplete(_ digits: [Int], uses24HourClock: Bool) -> Bool {
        isComplete(digits, largestLeadingDigit: uses24HourClock ? 2 : 1)
    }

    public static func isMinuteComplete(_ digits: [Int]) -> Bool {
        isComplete(digits, largestLeadingDigit: 5)
    }

    private static func isComplete(_ digits: [Int], largestLeadingDigit: Int) -> Bool {
        guard let first = digits.first else { return false }
        return digits.count >= 2 || first > largestLeadingDigit
    }
}
