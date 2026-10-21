import SwiftUI

struct LoginItemRow: View {
    @Environment(LoginItem.self) private var loginItem

    var body: some View {
        @Bindable var loginItem = loginItem
        VStack(alignment: .leading) {
            Toggle("Launch at login", isOn: $loginItem.isEnabled)
                .disabled(!loginItem.isAvailable)
            if !loginItem.isAvailable {
                Text("Available in the copy installed with make install.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            if loginItem.status == .requiresApproval {
                Button("Approve in System Settings…", action: loginItem.openSystemSettings)
            }
            if let message = loginItem.errorMessage {
                Text(message)
                    .font(.caption)
                    .foregroundStyle(.red)
            }
        }
        .task { loginItem.refresh() }
    }
}
