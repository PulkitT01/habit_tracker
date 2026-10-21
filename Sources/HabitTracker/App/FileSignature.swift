import Foundation

/// A file's modification date and size; nil when the file doesn't exist.
struct FileSignature: Equatable {
    let modified: Date?
    let size: Int?

    init?(of url: URL) {
        guard let values = try? url.resourceValues(forKeys: [.contentModificationDateKey, .fileSizeKey]) else {
            return nil // missing or unreadable; the reload that follows reports why
        }
        modified = values.contentModificationDate
        size = values.fileSize
    }
}
