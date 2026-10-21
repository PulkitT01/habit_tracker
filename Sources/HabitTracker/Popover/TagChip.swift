import SwiftUI

/// One optional tag of a binary habit, such as "new people" for socializing.
struct TagChip: View {
    let tag: String
    @Binding var isSelected: Bool
    @Environment(\.accessibilityDifferentiateWithoutColor) private var differentiateWithoutColor

    var body: some View {
        HStack(spacing: Design.chipVerticalPadding) {
            // The fill shows selection; add a mark when color can't carry it.
            if isSelected && differentiateWithoutColor {
                Image(systemName: "checkmark")
                    .imageScale(.small)
                    .accessibilityHidden(true)
            }
            Text(tag)
        }
        .font(.callout)
        .padding(.horizontal, Design.chipHorizontalPadding)
        .padding(.vertical, Design.chipVerticalPadding)
        .foregroundStyle(isSelected ? AnyShapeStyle(.white) : AnyShapeStyle(.primary))
        .background(isSelected ? AnyShapeStyle(.tint) : AnyShapeStyle(.quaternary), in: .capsule)
        .keyToggle(tag, isOn: $isSelected)
    }
}
