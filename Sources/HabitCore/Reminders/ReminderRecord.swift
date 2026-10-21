import Foundation

/// What has been shown for one group on one day.
public struct ReminderRecord: Sendable, Equatable, Codable {
    public static let empty = ReminderRecord(shownAt: nil, followUpDueAt: nil, followUpSent: false)

    /// When the reminder (or its catch-up) appeared.
    public let shownAt: Date?
    public let followUpDueAt: Date?
    public let followUpSent: Bool

    public init(shownAt: Date?, followUpDueAt: Date?, followUpSent: Bool) {
        self.shownAt = shownAt
        self.followUpDueAt = followUpDueAt
        self.followUpSent = followUpSent
    }
}
