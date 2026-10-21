import Charts
import HabitCore
import SwiftUI

/// Raw values as dots with the EWMA trend as a line.
struct TrendSparkline: View {
    let name: String
    let points: [TrendPoint]
    @Environment(\.timeZone) private var timeZone

    var body: some View {
        Chart {
            ForEach(points) { point in
                PointMark(x: .value("Day", date(of: point), unit: .day), y: .value("Logged", point.value))
                    .symbolSize(14)
                    .foregroundStyle(.secondary)
            }
            ForEach(points) { point in
                LineMark(x: .value("Day", date(of: point), unit: .day), y: .value("Trend", point.trend))
                    .foregroundStyle(.tint)
            }
        }
        .chartXAxis(.hidden)
        .chartYAxis(.hidden)
        .chartYScale(domain: .automatic(includesZero: false))
        .frame(height: Design.sparklineHeight)
        .accessibilityLabel("\(name), last \(StatsSnapshot.sparklineDays) days: logged values and trend")
    }

    private func date(of point: TrendPoint) -> Date {
        point.day.noon(in: timeZone)
    }
}
