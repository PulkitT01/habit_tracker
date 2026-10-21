import Foundation

/// Parses numbers typed into the popover. Accepts "." or "," as the decimal separator so
/// "72,4" works in any locale; rejects anything else rather than guessing.
public enum NumberInput {
    /// Longer counts can't be real and would overflow when converted.
    public static let maxCountDigits = 9

    /// - Parameter maxFractionDigits: the habit's `decimals`. More digits than that are rejected,
    ///   since "8,500" could mean 8.5 or 8500 and a separator can't tell which.
    public static func decimal(_ text: String, maxFractionDigits: Int = .max) -> Double? {
        let normalized = text.trimmingCharacters(in: .whitespaces).replacing(",", with: ".")
        guard normalized.contains(where: \.isNumber),
              normalized.allSatisfy({ $0.isASCII && ($0.isNumber || $0 == "." || $0 == "-") }),
              let value = Double(normalized), value.isFinite
        else { return nil }
        let fraction = normalized.split(separator: ".", maxSplits: 1, omittingEmptySubsequences: false).dropFirst().first ?? ""
        return fraction.count <= maxFractionDigits ? value : nil
    }

    /// A non-negative whole number.
    public static func count(_ text: String) -> Int? {
        let trimmed = text.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty, trimmed.count <= maxCountDigits, trimmed.allSatisfy({ $0.isASCII && $0.isNumber }) else {
            return nil
        }
        return Int(trimmed)
    }

    public static func rounded(_ value: Double, decimals: Int) -> Double {
        let scale = pow(10, Double(decimals))
        return (value * scale).rounded() / scale
    }
}
