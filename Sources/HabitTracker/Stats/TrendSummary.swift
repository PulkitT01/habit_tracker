import HabitCore
import SwiftUI

/// Latest value, EWMA trend and weekly rate for a trend habit, over a 28-day sparkline.
struct TrendSummary: View {
    let trend: HabitTrend
    let today: Day
    @Environment(\.timeZone) private var timeZone

    var body: some View {
        VStack(alignment: .leading) {
            Text(trend.habit.name)
                .font(.headline)
            if let latest = trend.series.latest {
                HStack(alignment: .top, spacing: Design.sectionSpacing) {
                    TrendFigure(title: latestTitle(for: latest.day), value: withUnit(latest.value))
                    TrendFigure(title: "Trend", value: withUnit(latest.trend))
                    TrendFigure(title: "Per week", value: weeklyRate)
                }
                TrendSparkline(
                    name: trend.habit.name,
                    points: trend.series.points(endingOn: today, days: StatsSnapshot.sparklineDays)
                )
            } else {
                Text("Nothing logged yet.")
                    .foregroundStyle(.secondary)
            }
        }
    }

    private func withUnit(_ value: Double) -> String {
        [HabitFormat.value(value, of: trend.habit), trend.habit.unit].compactMap(\.self).joined(separator: " ")
    }

    private var weeklyRate: String {
        guard let rate = trend.series.weeklyRate else { return "—" }
        let number = rate.formatted(.number.precision(.fractionLength(2)).sign(strategy: .always(includingZero: false)))
        return [number, trend.habit.unit].compactMap(\.self).joined(separator: " ")
    }

    private func latestTitle(for day: Day) -> LocalizedStringResource {
        if day == today {
            "Today"
        } else {
            "Latest (\(day.noon(in: timeZone).formatted(.dateTime.day().month(.abbreviated))))"
        }
    }
}
