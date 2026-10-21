import HabitCore
import SwiftUI

/// One day in the dot strip. States differ in shape as well as color:
/// filled = done, ✕ = not done, dotted ring = not logged, faint dash = not tracked yet.
struct DotView: View {
    let dot: DayDot
    @Environment(\.timeZone) private var timeZone

    var body: some View {
        Image(systemName: symbol)
            .resizable()
            .scaledToFit()
            .frame(width: Design.dotSize, height: Design.dotSize)
            .foregroundStyle(style)
            .help(description)
            .accessibilityLabel(description)
    }

    private var symbol: String {
        switch dot.state {
        case .done: "circle.fill"
        case .missed: "xmark.circle"
        case .notLogged: "circle.dotted"
        case .inactive: "minus"
        }
    }

    private var style: AnyShapeStyle {
        switch dot.state {
        case .done: AnyShapeStyle(.green)
        case .missed: AnyShapeStyle(.orange)
        case .notLogged: AnyShapeStyle(.secondary)
        case .inactive: AnyShapeStyle(.quaternary)
        }
    }

    private var description: String {
        let date = dot.day.noon(in: timeZone).formatted(.dateTime.weekday(.abbreviated).day().month(.abbreviated))
        return switch dot.state {
        case .done: String(localized: "\(date): done")
        case .missed: String(localized: "\(date): not done")
        case .notLogged: String(localized: "\(date): not logged")
        case .inactive: String(localized: "\(date): not tracked")
        }
    }
}
