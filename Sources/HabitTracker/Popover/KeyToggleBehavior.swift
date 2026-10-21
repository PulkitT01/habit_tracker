import SwiftUI

/// Makes a view act like a toggle that Tab reaches and Space flips, even when macOS
/// "Keyboard navigation" is off: `.edit` focus is always in the Tab loop, unlike buttons and
/// checkboxes. ⌫ calls `onClear`. VoiceOver sees an ordinary toggle.
struct KeyToggleBehavior: ViewModifier {
    let title: String
    @Binding var isOn: Bool
    var onClear: (() -> Void)?

    func body(content: Content) -> some View {
        content
            .contentShape(.rect)
            .focusable(interactions: .edit)
            .onKeyPress(.space) {
                isOn.toggle()
                return .handled
            }
            .onKeyPress(.delete) {
                guard let onClear else { return .ignored }
                onClear()
                return .handled
            }
            .onTapGesture { isOn.toggle() }
            .accessibilityRepresentation {
                Toggle(title, isOn: $isOn)
            }
    }
}

extension View {
    func keyToggle(_ title: String, isOn: Binding<Bool>, onClear: (() -> Void)? = nil) -> some View {
        modifier(KeyToggleBehavior(title: title, isOn: isOn, onClear: onClear))
    }
}
