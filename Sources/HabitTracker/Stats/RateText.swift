import HabitCore
import SwiftUI

/// "86%", or "—" when no day in the window counts yet.
struct RateText: View {
    let rate: CompletionRate
    let days: Int

    var body: some View {
        Text(HabitFormat.percent(rate.fraction))
            .monospacedDigit()
            .help(breakdown)
            .accessibilityLabel(breakdown)
    }

    private var breakdown: String {
        String(localized: "Last \(days) days: \(rate.done) done, \(rate.missed) not done, \(rate.notLogged) not logged")
    }
}
