/// An exponentially weighted moving average over a habit's logged values, oldest first.
///
/// The average steps once per logged value and starts at the first one, which matches pandas
/// `series.ewm(alpha=0.1, adjust=False).mean()` over the logged values in date order.
public struct TrendSeries: Sendable, Equatable {
    public static let alpha = 0.1
    public static let rateWindowDays = 7

    public let points: [TrendPoint]

    /// - Parameter values: logged values by day. Values ≤ 0 aren't real measurements and are skipped.
    public init(values: [Day: Double]) {
        points = values
            .filter { $0.value > 0 }
            .sorted { $0.key < $1.key }
            .reduce(into: []) { points, item in
                let trend = points.last.map { $0.trend + Self.alpha * (item.value - $0.trend) } ?? item.value
                points.append(TrendPoint(day: item.key, value: item.value, trend: trend))
            }
    }

    public var latest: TrendPoint? { points.last }

    /// Change in trend per week (e.g. kg/week), measured from the latest point back to the most
    /// recent point at least seven days earlier. nil until there is a week of history.
    public var weeklyRate: Double? {
        guard let last = points.last,
              let reference = points.last(where: { $0.day <= last.day.adding(days: -Self.rateWindowDays) })
        else { return nil }
        let days = Double(reference.day.days(until: last.day))
        return (last.trend - reference.trend) / days * Double(Self.rateWindowDays)
    }

    /// Points within the `days` days ending on `last`, for the sparkline. Trends still reflect the full history.
    public func points(endingOn last: Day, days: Int) -> [TrendPoint] {
        let first = last.adding(days: -(days - 1))
        return points.filter { $0.day >= first && $0.day <= last }
    }
}
