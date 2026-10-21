import HabitCore
import SwiftUI

struct SectionHeader: View {
    let prompt: Prompt
    let loggedCount: Int
    let totalCount: Int
    let isMarkedDone: Bool

    var body: some View {
        HStack {
            Text(prompt.title)
                .font(.headline)
            Spacer()
            Image(systemName: "checkmark.seal.fill")
                .foregroundStyle(.secondary)
                .help("Finished with Done")
                .accessibilityLabel("Finished with Done")
                .opacity(isMarkedDone ? 1 : 0)
                .accessibilityHidden(!isMarkedDone)
            Text("\(loggedCount)/\(totalCount)")
                .monospacedDigit()
                .foregroundStyle(.secondary)
                .accessibilityLabel("\(loggedCount) of \(totalCount) logged")
        }
    }
}
