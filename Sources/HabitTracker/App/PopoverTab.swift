import SwiftUI

enum PopoverTab: String, CaseIterable, Identifiable {
    case log
    case stats
    case settings

    var id: Self { self }

    var title: LocalizedStringResource {
        switch self {
        case .log: "Log"
        case .stats: "Stats"
        case .settings: "Settings"
        }
    }

    /// ⌘1, ⌘2, ⌘3.
    var shortcut: KeyEquivalent {
        switch self {
        case .log: "1"
        case .stats: "2"
        case .settings: "3"
        }
    }
}
