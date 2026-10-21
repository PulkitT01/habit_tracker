import Foundation

/// A problem with habits.json, phrased for display in the app's error banner.
public struct ConfigError: Error, Equatable, Sendable, CustomStringConvertible, LocalizedError {
    public let message: String

    public init(message: String) {
        self.message = message
    }

    public var description: String { message }
    public var errorDescription: String? { message }
}
