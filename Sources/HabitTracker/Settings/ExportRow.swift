import SwiftUI

struct ExportRow: View {
    @Environment(HabitStore.self) private var store
    @Environment(AppSettings.self) private var settings
    @State private var status: String?

    var body: some View {
        LabeledContent("Export") {
            Button("Export CSV…", action: export)
        }
        if let status {
            Text(status)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
    }

    private func export() {
        status = ExportAction.run(repository: store.repository, settings: settings)
    }
}
