import Foundation
import Testing
@testable import HabitCore

@Suite struct TimestampTests {
    @Test func formatsLocalTimeWithAColonSeparatedOffset() throws {
        let moment = try instant("2026-10-20T19:45:12Z")
        #expect(try Timestamp.string(from: moment, timeZone: zone("Europe/Berlin")) == "2026-10-20T21:45:12+02:00")
        #expect(try Timestamp.string(from: moment, timeZone: zone("Asia/Kolkata")) == "2026-10-21T01:15:12+05:30")
        #expect(try Timestamp.string(from: moment, timeZone: zone("America/New_York")) == "2026-10-20T15:45:12-04:00")
    }
}
