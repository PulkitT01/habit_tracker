import HabitCore
import SwiftUI

/// Rolling completion rates for every habit, plus the trend of measurement habits such as weight.
struct StatsView: View {
    @Environment(HabitStore.self) private var store

    var body: some View {
        ScrollView {
            if let stats = store.stats {
                VStack(alignment: .leading, spacing: Design.sectionSpacing) {
                    ForEach(stats.trends) { trend in
                        TrendSummary(trend: trend, today: store.today)
                    }
                    RatesGrid(rates: stats.rates)
                    DotLegend()
                }
                .padding()
            } else {
                ContentUnavailableView("No Stats Yet", systemImage: "chart.bar")
            }
        }
    }
}
