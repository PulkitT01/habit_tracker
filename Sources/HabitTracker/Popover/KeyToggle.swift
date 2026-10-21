import SwiftUI

/// The checkbox for binary habits.
struct KeyToggle: View {
    let title: String
    @Binding var isOn: Bool
    var onClear: (() -> Void)?

    var body: some View {
        Image(systemName: isOn ? "checkmark.square.fill" : "square")
            .font(.title3)
            .foregroundStyle(isOn ? AnyShapeStyle(.tint) : AnyShapeStyle(.secondary))
            .keyToggle(title, isOn: $isOn, onClear: onClear)
    }
}
