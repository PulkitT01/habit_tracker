import Foundation
import Observation
import ServiceManagement

/// "Launch at login" via SMAppService. The system's status is the source of truth.
@Observable
final class LoginItem {
    private(set) var status: SMAppService.Status = .notRegistered
    private(set) var errorMessage: String?

    /// Only the installed copy should register: a login item pointing into .build would break
    /// on the next `make clean`.
    var isAvailable: Bool {
        guard Bundle.main.bundleIdentifier != nil else { return false }
        let folder = Bundle.main.bundleURL.deletingLastPathComponent().standardizedFileURL
        let applicationFolders = [URL(filePath: "/Applications"), URL.homeDirectory.appending(path: "Applications")]
        return applicationFolders.contains { $0.standardizedFileURL == folder }
    }

    var isEnabled: Bool {
        get { status == .enabled }
        set { setEnabled(newValue) }
    }

    func refresh() {
        status = SMAppService.mainApp.status
    }

    func openSystemSettings() {
        SMAppService.openSystemSettingsLoginItems()
    }

    private func setEnabled(_ enabled: Bool) {
        do {
            if enabled {
                try SMAppService.mainApp.register()
            } else {
                try SMAppService.mainApp.unregister()
            }
            errorMessage = nil
        } catch {
            Log.app.error("Login item change failed: \(error.localizedDescription, privacy: .public)")
            errorMessage = error.localizedDescription
        }
        refresh()
    }
}
