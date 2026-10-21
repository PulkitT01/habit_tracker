import AppKit
import HabitCore

/// Fires when the logical day may have changed (04:00, wake from sleep, time-zone or clock
/// changes) and when the Mac is about to sleep or has woken.
final class DayClock {
    private let onDayMayHaveChanged: () -> Void
    private let onSleep: () -> Void
    private let onWake: () -> Void
    private var boundaryTimer: Task<Void, Never>?
    private var observers: [any NSObjectProtocol] = []

    init(onDayMayHaveChanged: @escaping () -> Void, onSleep: @escaping () -> Void, onWake: @escaping () -> Void) {
        self.onDayMayHaveChanged = onDayMayHaveChanged
        self.onSleep = onSleep
        self.onWake = onWake
    }

    func start() {
        let workspace = NSWorkspace.shared.notificationCenter
        let center = NotificationCenter.default
        observers = [
            workspace.addObserver(forName: NSWorkspace.willSleepNotification, object: nil, queue: .main) { [weak self] _ in
                MainActor.assumeIsolated { self?.onSleep() }
            },
            workspace.addObserver(forName: NSWorkspace.didWakeNotification, object: nil, queue: .main) { [weak self] _ in
                MainActor.assumeIsolated {
                    self?.tick()
                    self?.onWake() // last, so its delayed replan isn't replaced by tick's quicker one
                }
            },
            center.addObserver(forName: .NSSystemTimeZoneDidChange, object: nil, queue: .main) { [weak self] _ in
                MainActor.assumeIsolated { self?.tick() }
            },
            center.addObserver(forName: .NSSystemClockDidChange, object: nil, queue: .main) { [weak self] _ in
                MainActor.assumeIsolated { self?.tick() }
            },
        ]
        scheduleNextBoundary()
    }

    private func tick() {
        onDayMayHaveChanged()
        scheduleNextBoundary()
    }

    /// Sleeps until just after the next 04:00. The continuous clock keeps counting while the
    /// Mac sleeps, so an overdue boundary fires right after wake.
    private func scheduleNextBoundary() {
        boundaryTimer?.cancel()
        let next = DayBoundary(timeZone: .autoupdatingCurrent).nextStart(after: .now)
        let delay = max(next.timeIntervalSinceNow, 0) + 1
        boundaryTimer = Task { [weak self] in
            do {
                try await Task.sleep(for: .seconds(delay))
            } catch {
                return // cancelled by a newer schedule
            }
            self?.tick()
        }
    }
}
