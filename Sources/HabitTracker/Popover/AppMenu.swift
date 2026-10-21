import AppKit
import SwiftUI

/// The gear menu: config, data folder, quit.
struct AppMenu: View {
    @Environment(HabitStore.self) private var store

    var body: some View {
        Menu("More", systemImage: "gearshape") {
            Button("Reload Config", action: store.reloadConfig)
                .keyboardShortcut("r")
            Button("Edit habits.json", action: editConfig)
            Button("Show Data Folder", action: showDataFolder)
            Divider()
            Button("Quit HabitTracker", action: quit)
                .keyboardShortcut("q")
        }
        .menuStyle(.borderlessButton)
        .menuIndicator(.hidden)
        .labelStyle(.iconOnly)
        .fixedSize()
    }

    private func editConfig() {
        NSWorkspace.shared.open(store.paths.config)
    }

    private func showDataFolder() {
        NSWorkspace.shared.activateFileViewerSelecting([store.paths.config])
    }

    private func quit() {
        NSApp.terminate(nil)
    }
}
