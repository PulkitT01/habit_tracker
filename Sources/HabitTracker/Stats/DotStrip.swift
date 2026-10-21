import HabitCore
import SwiftUI

/// Seven dots, oldest first, ending today.
struct DotStrip: View {
    let dots: [DayDot]

    var body: some View {
        HStack(spacing: Design.dotSize / 2) {
            ForEach(dots) { dot in
                DotView(dot: dot)
            }
        }
        .accessibilityElement(children: .contain)
    }
}
