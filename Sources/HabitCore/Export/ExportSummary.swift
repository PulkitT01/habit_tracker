import Foundation

public struct ExportSummary: Sendable, Equatable {
    public let entryCount: Int
    public let noteCount: Int
    public let folder: URL
}
