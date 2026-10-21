import Foundation
import HabitCore
import Observation

/// Reminder times and other preferences, persisted in UserDefaults.
@Observable
final class AppSettings {
    static let defaultMorningReminder = TimeOfDay(hour: 8, minute: 30)
    static let defaultEveningReminder = TimeOfDay(hour: 21, minute: 30)
    static let defaultFollowUpMinutes = 45
    static let followUpRange = 15...120

    private enum Key {
        static let morningReminder = "morningReminder"
        static let eveningReminder = "eveningReminder"
        static let followUpMinutes = "followUpMinutes"
        static let lastExportFolder = "lastExportFolder"
    }

    @ObservationIgnored private let defaults: UserDefaults
    /// Called after a reminder setting changes so notifications can be rescheduled.
    @ObservationIgnored var onRemindersChanged: (() -> Void)?

    var morningReminder: TimeOfDay {
        didSet {
            defaults.set(morningReminder.description, forKey: Key.morningReminder)
            onRemindersChanged?()
        }
    }

    var eveningReminder: TimeOfDay {
        didSet {
            defaults.set(eveningReminder.description, forKey: Key.eveningReminder)
            onRemindersChanged?()
        }
    }

    var followUpMinutes: Int {
        didSet {
            defaults.set(followUpMinutes, forKey: Key.followUpMinutes)
            onRemindersChanged?()
        }
    }

    var lastExportFolder: URL? {
        didSet { defaults.set(lastExportFolder, forKey: Key.lastExportFolder) }
    }

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        morningReminder = defaults.string(forKey: Key.morningReminder).flatMap(TimeOfDay.init) ?? Self.defaultMorningReminder
        eveningReminder = defaults.string(forKey: Key.eveningReminder).flatMap(TimeOfDay.init) ?? Self.defaultEveningReminder
        let storedFollowUp = defaults.integer(forKey: Key.followUpMinutes)
        followUpMinutes = Self.followUpRange.contains(storedFollowUp) ? storedFollowUp : Self.defaultFollowUpMinutes
        lastExportFolder = defaults.url(forKey: Key.lastExportFolder)
    }

    /// Time pickers bind to dates; only the hour and minute matter.
    var morningReminderDate: Date {
        get { morningReminder.date(on: Self.pickerDay, in: .autoupdatingCurrent) }
        set { morningReminder = TimeOfDay(of: newValue, in: .autoupdatingCurrent) }
    }

    var eveningReminderDate: Date {
        get { eveningReminder.date(on: Self.pickerDay, in: .autoupdatingCurrent) }
        set { eveningReminder = TimeOfDay(of: newValue, in: .autoupdatingCurrent) }
    }

    private static var pickerDay: Day {
        Day(calendarDateOf: .now, in: .autoupdatingCurrent)
    }

    var reminderSettings: ReminderSettings {
        ReminderSettings(morning: morningReminder, evening: eveningReminder, followUpMinutes: followUpMinutes)
    }
}
