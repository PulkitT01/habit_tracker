import SwiftUI

/// Invisible buttons that carry popover-wide shortcuts: ⌘1–⌘3 for tabs and ⌘R to reload the
/// config. (Shortcuts on items of a closed menu don't fire, and a segmented picker can't hold any.)
struct GlobalShortcuts: View {
    @Binding var selection: PopoverTab
    @Environment(HabitStore.self) private var store

    var body: some View {
        ZStack {
            ForEach(PopoverTab.allCases) { tab in
                Button(tab.title) {
                    selection = tab
                }
                .keyboardShortcut(tab.shortcut, modifiers: .command)
                .focusable(false)
            }
            Button("Reload Config", action: store.reloadConfig)
                .keyboardShortcut("r", modifiers: .command)
                .focusable(false)
        }
        .opacity(0)
        .frame(width: 0, height: 0)
        .accessibilityHidden(true)
    }
}
