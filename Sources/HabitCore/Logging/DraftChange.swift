/// What to do after the text of a number or count field changes.
public enum DraftChange: Sendable, Equatable {
    /// Not an edit (the field only shows the stored value), or text that can't be saved.
    case ignore
    /// Write this value; nil clears the entry back to "not logged".
    case save(Double?)
}
