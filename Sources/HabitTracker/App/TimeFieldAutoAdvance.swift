import AppKit
import HabitCore

/// Moves on once part of a time is typed, as if Tab were pressed: from the hour ("08" or "9") to
/// the minutes, and from the minutes ("45" or "7") to the next field, such as bedtime to wake
/// time. NSDatePicker doesn't do this by itself. A local key monitor covers every hour-and-minute
/// DatePicker in the app (sleep, reminder times), so the SwiftUI pickers stay as they are.
final class TimeFieldAutoAdvance {
    private enum Part {
        case hour, minute, dayPeriod, unknown
    }

    private var monitor: Any?
    private var observer: (any NSObjectProtocol)?
    /// The time field that had focus at the last event; nil after focus was elsewhere.
    private weak var picker: NSDatePicker?
    private var part = Part.unknown
    /// Digits typed into the current part; empty when the next digit starts a part.
    private var digits: [Int] = []
    /// Focus reached the field by keyboard, so typing starts at the hour. NSDatePicker would
    /// keep the part it had last time, such as the minutes it moved on from.
    private var startsAtHour = false

    func start() {
        monitor = NSEvent.addLocalMonitorForEvents(matching: [.keyDown, .leftMouseDown]) { [weak self] event in
            guard let self else { return event }
            return handle(event) // nil when the key was handled here
        }
        // Closing the popover moves focus without a key or click this monitor would see.
        observer = NotificationCenter.default.addObserver(
            forName: NSWindow.didResignKeyNotification, object: nil, queue: .main
        ) { [weak self] _ in
            MainActor.assumeIsolated { self?.picker = nil }
        }
    }

    private func handle(_ event: NSEvent) -> NSEvent? {
        if event.type == .leftMouseDown {
            // A click picks the part itself.
            picker = Self.timePicker(at: event)
            digits = []
            startsAtHour = false
            return event
        }
        guard let picker = event.window?.firstResponder as? NSDatePicker, Self.isTimePicker(picker) else {
            self.picker = nil
            return event
        }
        if picker !== self.picker {
            self.picker = picker
            digits = []
            startsAtHour = true
        }
        guard let digit = Self.digit(of: event) else {
            digits = [] // Tab and arrows change or finish the part
            startsAtHour = false
            return event
        }
        if digits.isEmpty {
            part = Self.selectedPart(of: picker, keyEvent: event)
            if startsAtHour {
                // ⇧⇥ inside the field steps back: AM/PM → minutes → hour. From the hour (or an
                // unknown part) it would leave the field, so stop there.
                for _ in 0..<2 where part == .minute || part == .dayPeriod {
                    picker.keyDown(with: Self.key(.backTab, like: event))
                    part = Self.selectedPart(of: picker, keyEvent: event)
                }
                startsAtHour = false
            }
        }
        picker.keyDown(with: event)
        digits.append(digit)
        let isComplete = switch part {
        case .hour: TimeTyping.isHourComplete(digits, uses24HourClock: Self.uses24HourClock(picker))
        case .minute: TimeTyping.isMinuteComplete(digits)
        case .dayPeriod, .unknown: false
        }
        if isComplete {
            // Like pressing Tab: hour → minutes, minutes → AM/PM or the next field.
            event.window?.sendEvent(Self.key(.tab, like: event))
        }
        if isComplete || digits.count == 2 { digits = [] }
        return nil
    }

    private static func isTimePicker(_ picker: NSDatePicker) -> Bool {
        picker.datePickerElements == .hourMinute
    }

    private static func timePicker(at event: NSEvent) -> NSDatePicker? {
        var view = event.window?.contentView?.hitTest(event.locationInWindow)
        while let current = view, !(current is NSDatePicker) {
            view = current.superview
        }
        return (view as? NSDatePicker).flatMap { isTimePicker($0) ? $0 : nil }
    }

    private static func digit(of event: NSEvent) -> Int? {
        let modifiers = event.modifierFlags.intersection([.command, .control, .option, .shift])
        guard modifiers.isEmpty, let characters = event.charactersIgnoringModifiers, characters.count == 1 else {
            return nil
        }
        return Int(characters)
    }

    /// AppKit doesn't say which part is selected, so press ↑ with the action detached, see what
    /// changed, and put the value back. Nothing reaches the binding.
    private static func selectedPart(of picker: NSDatePicker, keyEvent: NSEvent) -> Part {
        let original = picker.dateValue
        let (target, action) = (picker.target, picker.action)
        picker.target = nil
        picker.action = nil
        picker.keyDown(with: key(.upArrow, like: keyEvent))
        let stepped = picker.dateValue
        picker.dateValue = original
        picker.target = target
        picker.action = action

        var calendar = picker.calendar ?? .current
        calendar.timeZone = picker.timeZone ?? .current
        let before = calendar.dateComponents([.hour, .minute], from: original)
        let after = calendar.dateComponents([.hour, .minute], from: stepped)
        if before.minute != after.minute { return .minute }
        if let oldHour = before.hour, let newHour = after.hour, (newHour - oldHour + 24) % 24 == 12 {
            return .dayPeriod
        }
        // Compare instants, not clock readings: on the night clocks go back, ↑ from 02:00 gives
        // the second 02:00.
        return stepped != original ? .hour : .unknown
    }

    private static func uses24HourClock(_ picker: NSDatePicker) -> Bool {
        switch (picker.locale ?? .autoupdatingCurrent).hourCycle {
        case .zeroToTwentyThree, .oneToTwentyFour: true
        case .zeroToEleven, .oneToTwelve: false
        @unknown default: true
        }
    }

    private enum Key {
        case tab, backTab, upArrow
    }

    private static func key(_ key: Key, like event: NSEvent) -> NSEvent {
        let (characters, keyCode, modifiers): (String, UInt16, NSEvent.ModifierFlags) = switch key {
        case .tab: ("\t", 48, [])
        case .backTab: (String(UnicodeScalar(UInt16(NSBackTabCharacter))!), 48, .shift)
        case .upArrow: (String(UnicodeScalar(UInt16(NSUpArrowFunctionKey))!), 126, [.numericPad, .function])
        }
        return NSEvent.keyEvent(
            with: .keyDown,
            location: event.locationInWindow,
            modifierFlags: modifiers,
            timestamp: event.timestamp,
            windowNumber: event.windowNumber,
            context: nil,
            characters: characters,
            charactersIgnoringModifiers: characters,
            isARepeat: false,
            keyCode: keyCode
        )!
    }
}
