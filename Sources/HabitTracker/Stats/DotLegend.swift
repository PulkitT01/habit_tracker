import SwiftUI

/// Explains the dot shapes and how rates are counted.
struct DotLegend: View {
    var body: some View {
        VStack(alignment: .leading) {
            HStack(spacing: Design.sectionSpacing) {
                Label("done", systemImage: "circle.fill").foregroundStyle(.green)
                Label("not done", systemImage: "xmark.circle").foregroundStyle(.orange)
                Label("not logged", systemImage: "circle.dotted").foregroundStyle(.secondary)
            }
            Text("Rates count unlogged past days as not done; days before a habit started don't count. Today counts once it's logged.")
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .font(.caption)
    }
}
