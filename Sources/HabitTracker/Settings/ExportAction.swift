import AppKit
import HabitCore

/// Export CSV: pick a folder, write entries.csv and day_notes.csv, reveal them in Finder.
enum ExportAction {
    /// Returns a status line for the Settings tab, or nil if the user cancelled.
    static func run(repository: EntryRepository, settings: AppSettings) -> String? {
        // The panel is app-modal rather than attached to the popover, which closes when it loses focus.
        NSApp.activate()
        let panel = NSOpenPanel()
        panel.title = String(localized: "Export CSV")
        panel.message = String(localized: "Choose a folder for entries.csv and day_notes.csv. Files with those names are replaced.")
        panel.prompt = String(localized: "Export")
        panel.canChooseFiles = false
        panel.canChooseDirectories = true
        panel.canCreateDirectories = true
        panel.allowsMultipleSelection = false
        panel.directoryURL = settings.lastExportFolder ?? .documentsDirectory
        guard panel.runModal() == .OK, let folder = panel.url else { return nil }

        settings.lastExportFolder = folder
        do {
            let summary = try Exporter.export(from: repository, to: folder)
            NSWorkspace.shared.activateFileViewerSelecting([
                folder.appending(path: Exporter.entriesFileName),
                folder.appending(path: Exporter.notesFileName),
            ])
            return String(localized: "Exported \(summary.entryCount) entries and \(summary.noteCount) notes to “\(folder.lastPathComponent)”.")
        } catch {
            Log.app.error("Export failed: \(error.localizedDescription, privacy: .public)")
            return String(localized: "Export failed: \(error.localizedDescription)")
        }
    }
}
