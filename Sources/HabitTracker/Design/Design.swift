import Foundation

/// Shared sizes so every view lays out the same way.
enum Design {
    /// MenuBarExtra windows grow but never shrink, so every tab uses one fixed frame.
    static let popoverWidth = 380.0
    static let popoverHeight = 600.0

    static let sectionSpacing = 16.0
    static let gridColumnSpacing = 10.0
    static let gridRowSpacing = 8.0
    static let numberFieldWidth = 56.0
    static let cornerRadius = 8.0
    static let fieldCornerRadius = 4.0
    static let chipHorizontalPadding = 8.0
    static let chipVerticalPadding = 2.0

    static let dotSize = 10.0
    static let sparklineHeight = 44.0
}
