import HabitCore
import SwiftUI

/// Trailing marker that keeps "not done" (0) visibly different from "not logged".
struct StatusGlyph: View {
    let state: DotState

    var body: some View {
        Image(systemName: symbol)
            .foregroundStyle(style)
            .help(label)
            .accessibilityLabel(label)
    }

    private var symbol: String {
        switch state {
        case .done: "checkmark.circle.fill"
        case .missed: "xmark.circle"
        case .notLogged: "circle.dotted"
        case .inactive: "minus"
        }
    }

    private var style: AnyShapeStyle {
        switch state {
        case .done: AnyShapeStyle(.green)
        case .missed: AnyShapeStyle(.orange)
        case .notLogged, .inactive: AnyShapeStyle(.tertiary)
        }
    }

    private var label: String {
        switch state {
        case .done: String(localized: "Done")
        case .missed: String(localized: "Logged, not done")
        case .notLogged: String(localized: "Not logged")
        case .inactive: String(localized: "Not tracked yet")
        }
    }
}
