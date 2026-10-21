import HabitCore
import SwiftUI

/// Habit | last 7 days | 7d | 28d.
struct RatesGrid: View {
    let rates: [HabitRates]

    var body: some View {
        Grid(alignment: .leading, horizontalSpacing: Design.gridColumnSpacing, verticalSpacing: Design.gridRowSpacing) {
            GridRow {
                Text("Habit")
                Text("Last 7 days")
                Text("7d")
                    .gridColumnAlignment(.trailing)
                Text("28d")
                    .gridColumnAlignment(.trailing)
            }
            .font(.caption)
            .foregroundStyle(.secondary)
            ForEach(rates) { rate in
                HabitStatsRow(rates: rate)
            }
        }
    }
}
