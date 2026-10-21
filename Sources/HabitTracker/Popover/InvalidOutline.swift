import SwiftUI

/// A red outline around a field whose text can't be saved.
struct InvalidOutline: ViewModifier {
    let isInvalid: Bool

    func body(content: Content) -> some View {
        content.overlay {
            RoundedRectangle(cornerRadius: Design.fieldCornerRadius)
                .stroke(.red)
                .opacity(isInvalid ? 1 : 0)
        }
    }
}

extension View {
    func invalidOutline(_ isInvalid: Bool) -> some View {
        modifier(InvalidOutline(isInvalid: isInvalid))
    }
}
