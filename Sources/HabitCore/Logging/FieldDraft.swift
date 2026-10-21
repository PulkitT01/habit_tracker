import Foundation

/// Rules for number and count fields, which edit their own text and save as you type.
/// Text that still reads as the stored value is never saved, so merely displaying a day can't
/// rewrite a value (72.76 written elsewhere shows as "72.8" but stays 72.76).
public enum FieldDraft {
    /// - Parameters:
    ///   - text: what the field now says.
    ///   - storedText: the stored value as the field displays it ("" when not logged).
    ///   - parsed: `text` parsed and rounded the way it would be stored; nil if blank or invalid.
    public static func change(text: String, storedText: String, storedValue: Double?, parsed: Double?) -> DraftChange {
        guard text != storedText else { return .ignore }
        if text.trimmingCharacters(in: .whitespaces).isEmpty {
            return storedValue == nil ? .ignore : .save(nil)
        }
        guard let parsed, parsed != storedValue else { return .ignore }
        return .save(parsed)
    }

    /// After the stored value changed elsewhere (stepper, Done, another day), whether the field
    /// should show it. Text that already means the stored value, such as "72." mid-typing, is kept.
    public static func shouldShowStoredValue(parsed: Double?, storedValue: Double?) -> Bool {
        parsed != storedValue
    }
}
