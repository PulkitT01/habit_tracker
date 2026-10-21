import HabitCore
import SwiftUI

/// One habit: its dot strip and rolling rates. Hover a rate for the done / missed / not-logged split.
struct HabitStatsRow: View {
    let rates: HabitRates

    var body: some View {
        GridRow {
            Text(rates.habit.name)
                .lineLimit(1)
            DotStrip(dots: rates.dots)
            RateText(rate: rates.week, days: HabitRates.shortWindow)
            RateText(rate: rates.month, days: HabitRates.longWindow)
        }
    }
}
