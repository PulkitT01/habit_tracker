import MenuBarExtraAccess
import SwiftUI

@main
struct HabitTrackerApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate

    var body: some Scene {
        MenuBarExtra {
            PopoverView()
                .environment(appDelegate.store)
                .environment(appDelegate.settings)
                .environment(appDelegate.notifications)
                .environment(appDelegate.loginItem)
        } label: {
            MenuBarIcon()
                .environment(appDelegate.store)
        }
        // Must come before the style modifier (MenuBarExtraAccess requirement).
        .menuBarExtraAccess(isPresented: Bindable(appDelegate.store).isPopoverPresented)
        .menuBarExtraStyle(.window)
    }
}
