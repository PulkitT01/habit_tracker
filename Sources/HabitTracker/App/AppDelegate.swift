import AppKit
import HabitCore

/// Builds the app's long-lived objects and wires them together.
final class AppDelegate: NSObject, NSApplicationDelegate {
    let settings: AppSettings
    let store: HabitStore
    let notifications: NotificationService
    let loginItem = LoginItem()
    private let reminders: ReminderController
    private let dayClock: DayClock
    private let configWatcher: ConfigWatcher
    private var terminationSignal: (any DispatchSourceSignal)?
    private var isDuplicateInstance = false

    override init() {
        let paths = AppPaths.current
        let settings = AppSettings()
        let (repository, startupError) = Self.openRepository(paths: paths)
        let store = HabitStore(repository: repository, paths: paths, settings: settings, startupError: startupError)
        // Created before launch finishes so a click on a notification that launched the app is handled.
        let notifications = NotificationService()
        let reminders = ReminderController(store: store, settings: settings, notifications: notifications)

        self.settings = settings
        self.store = store
        self.notifications = notifications
        self.reminders = reminders
        dayClock = DayClock(
            onDayMayHaveChanged: { [weak store, weak reminders] in
                store?.refreshToday()
                reminders?.requestReplan() // reminder times are wall-clock times in the current zone
            },
            onSleep: { [weak reminders] in reminders?.systemWillSleep() },
            onWake: { [weak reminders] in reminders?.systemDidWake() }
        )
        configWatcher = ConfigWatcher(url: paths.config) { [weak store] in store?.reloadConfig() }
        super.init()

        store.onRemindersNeedUpdate = { [weak reminders] in reminders?.requestReplan() }
        settings.onRemindersChanged = { [weak reminders] in reminders?.requestReplan() }
        notifications.onOpen = { [weak store, weak reminders] opened in
            reminders?.recordShown(opened)
            store?.openPopover(on: opened.day)
        }
        notifications.onAuthorizationGranted = { [weak reminders] in reminders?.requestReplan() }
    }

    func applicationWillFinishLaunching(_ notification: Notification) {
        quitIfAlreadyRunning()
        quitGracefullyOnSIGTERM()
    }

    func applicationDidFinishLaunching(_ notification: Notification) {
        guard store.startupError == nil, !isDuplicateInstance else { return }
        dayClock.start()
        configWatcher.start()
        reminders.start()
    }

    func applicationWillTerminate(_ notification: Notification) {
        // The installed app keeps its pending reminders: clicking one relaunches it. A duplicate
        // copy that is quitting must not clear the reminders of the copy that keeps running.
        if AppPaths.isDevBuild, !isDuplicateInstance {
            notifications.removeAll()
        }
    }

    /// `make run` and `make install` stop the app with SIGTERM; turn that into a normal quit so
    /// `applicationWillTerminate` runs. (Signals have no Swift-concurrency API, hence Dispatch.)
    private func quitGracefullyOnSIGTERM() {
        signal(SIGTERM, SIG_IGN)
        let source = DispatchSource.makeSignalSource(signal: SIGTERM, queue: .main)
        source.setEventHandler {
            MainActor.assumeIsolated { NSApp.terminate(nil) }
        }
        source.resume()
        terminationSignal = source
    }

    /// Two copies with the same bundle id would show two icons and double every reminder.
    private func quitIfAlreadyRunning() {
        guard let identifier = Bundle.main.bundleIdentifier else { return }
        let others = NSRunningApplication.runningApplications(withBundleIdentifier: identifier)
            .filter { $0.processIdentifier != ProcessInfo.processInfo.processIdentifier }
        guard !others.isEmpty else { return }
        isDuplicateInstance = true
        Log.app.notice("Another copy is already running; quitting")
        NSApp.terminate(nil)
    }

    /// Opens the database. If that fails the app still starts, showing the error instead of
    /// the log, so nothing can be entered into a throwaway database.
    private static func openRepository(paths: AppPaths) -> (EntryRepository, String?) {
        do {
            return (EntryRepository(try AppDatabase.open(at: paths.database)), nil)
        } catch {
            Log.app.fault("Couldn't open the database: \(error.localizedDescription, privacy: .public)")
            guard let placeholder = try? AppDatabase.inMemory() else {
                fatalError("Couldn't create an in-memory database: \(error)")
            }
            let message = "Couldn't open \(paths.database.path(percentEncoded: false)): \(error.localizedDescription)"
            return (EntryRepository(placeholder), message)
        }
    }
}
