import Foundation
import Testing
@testable import HabitCore

/// An absolute instant from an ISO 8601 string such as "2026-10-20T19:30:00Z".
func instant(_ iso: String) throws -> Date {
    try Date(iso, strategy: .iso8601)
}

/// A `Day` from "YYYY-MM-DD".
func day(_ iso: String) throws -> Day {
    try #require(Day(iso))
}

func zone(_ identifier: String) throws -> TimeZone {
    try #require(TimeZone(identifier: identifier))
}

/// A habit with sensible defaults for tests.
func habit(
    _ id: String,
    _ type: HabitType = .binary,
    prompt: Prompt = .evening,
    minTarget: Double? = nil,
    from activeFrom: String = "2026-10-01",
    to activeTo: String? = nil
) throws -> Habit {
    try Habit(
        id: id, name: id.capitalized, type: type, minTarget: minTarget, prompt: prompt, order: 0,
        activeFrom: day(activeFrom), activeTo: activeTo.map(day)
    )
}

/// Values keyed by day from `[("2026-10-20", 1), ...]`.
func values(_ pairs: [(String, Double)]) throws -> [Day: Double] {
    try Dictionary(uniqueKeysWithValues: pairs.map { (try day($0.0), $0.1) })
}
