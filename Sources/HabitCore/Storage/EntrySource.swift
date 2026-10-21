/// Values of `entries.source`. Stored as free text so future clients (a phone app, an importer)
/// can add their own without breaking older readers.
public enum EntrySource {
    /// Entered with a control in the app.
    public static let manual = "manual"
    /// Written as 0 by the Done button for a binary or count habit you didn't touch.
    public static let autoZero = "auto_zero"
}
