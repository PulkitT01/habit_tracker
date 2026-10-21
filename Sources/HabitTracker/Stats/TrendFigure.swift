import SwiftUI

/// A number with a caption underneath, e.g. "72.4 kg / Trend".
struct TrendFigure: View {
    let title: LocalizedStringResource
    let value: String

    var body: some View {
        VStack(alignment: .leading) {
            Text(value)
                .font(.title3)
                .monospacedDigit()
            Text(title)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .accessibilityElement(children: .combine)
    }
}
