import SwiftUI

/// Log | Stats | Settings, plus the gear menu.
struct TabBar: View {
    @Binding var selection: PopoverTab

    var body: some View {
        HStack {
            Picker("Section", selection: $selection) {
                ForEach(PopoverTab.allCases) { tab in
                    Text(tab.title).tag(tab)
                }
            }
            .pickerStyle(.segmented)
            .labelsHidden()
            AppMenu()
        }
        .background {
            GlobalShortcuts(selection: $selection)
        }
    }
}
