/// A logged value with its EWMA trend at that point.
public struct TrendPoint: Sendable, Equatable, Identifiable {
    public let day: Day
    public let value: Double
    public let trend: Double

    public var id: Day { day }

    public init(day: Day, value: Double, trend: Double) {
        self.day = day
        self.value = value
        self.trend = trend
    }
}
