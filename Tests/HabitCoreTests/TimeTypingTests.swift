import Testing
@testable import HabitCore

@Suite struct TimeTypingTests {
    @Test func twoDigitsCompleteTheHour() {
        #expect(TimeTyping.isHourComplete([0, 8], uses24HourClock: true))
        #expect(TimeTyping.isHourComplete([2, 3], uses24HourClock: true))
        #expect(TimeTyping.isHourComplete([1, 1], uses24HourClock: false))
    }

    @Test func aDigitThatCouldStartATwoDigitHourWaits() {
        #expect(!TimeTyping.isHourComplete([0], uses24HourClock: true))
        #expect(!TimeTyping.isHourComplete([1], uses24HourClock: true))
        #expect(!TimeTyping.isHourComplete([2], uses24HourClock: true)) // 20–23
        #expect(!TimeTyping.isHourComplete([1], uses24HourClock: false)) // 10–12
    }

    @Test func aDigitNoHourCanContinueIsComplete() {
        #expect(TimeTyping.isHourComplete([3], uses24HourClock: true))
        #expect(TimeTyping.isHourComplete([9], uses24HourClock: true))
        #expect(TimeTyping.isHourComplete([2], uses24HourClock: false))
    }

    @Test func minutesCompleteAfterTwoDigitsOrOneAbove5() {
        #expect(TimeTyping.isMinuteComplete([4, 5]))
        #expect(TimeTyping.isMinuteComplete([0, 0]))
        #expect(TimeTyping.isMinuteComplete([6])) // no minute 60–69
        #expect(!TimeTyping.isMinuteComplete([5])) // 50–59
        #expect(!TimeTyping.isMinuteComplete([0]))
    }

    @Test func nothingTypedIsIncomplete() {
        #expect(!TimeTyping.isHourComplete([], uses24HourClock: true))
        #expect(!TimeTyping.isMinuteComplete([]))
    }
}
