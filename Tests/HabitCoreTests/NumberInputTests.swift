import Testing
@testable import HabitCore

@Suite struct NumberInputTests {
    @Test(arguments: [("72.4", 72.4), ("72,4", 72.4), (" 72.4 ", 72.4), ("72", 72.0), ("72.", 72.0), (".5", 0.5), ("0", 0.0)])
    func parsesDecimalsWithEitherSeparator(text: String, expected: Double) {
        #expect(NumberInput.decimal(text) == expected)
    }

    @Test(arguments: ["", "  ", "abc", "1.2.3", "72kg", "nan", "inf", "1e5", "-"])
    func rejectsInvalidDecimals(text: String) {
        #expect(NumberInput.decimal(text) == nil)
    }

    @Test(arguments: [("20", 20), (" 5 ", 5), ("0", 0), ("007", 7)])
    func parsesCounts(text: String, expected: Int) {
        #expect(NumberInput.count(text) == expected)
    }

    @Test(arguments: ["", "-3", "2.5", "ten", "1,000"])
    func rejectsInvalidCounts(text: String) {
        #expect(NumberInput.count(text) == nil)
    }

    @Test func roundsToTheHabitsDecimals() {
        #expect(NumberInput.rounded(72.45, decimals: 1) == 72.5)
        #expect(NumberInput.rounded(72.44, decimals: 1) == 72.4)
        #expect(NumberInput.rounded(41.6, decimals: 0) == 42)
    }

    @Test func rejectsMoreFractionDigitsThanTheHabitStores() {
        // "8,500" is eight and a half thousand to some people and 8.5 to others: never guess.
        #expect(NumberInput.decimal("8,500", maxFractionDigits: 0) == nil)
        #expect(NumberInput.decimal("1.000", maxFractionDigits: 1) == nil)
        #expect(NumberInput.decimal("72,45", maxFractionDigits: 1) == nil)
        #expect(NumberInput.decimal("72,4", maxFractionDigits: 1) == 72.4)
        #expect(NumberInput.decimal("72.", maxFractionDigits: 1) == 72)
        #expect(NumberInput.decimal("45", maxFractionDigits: 0) == 45)
    }

    @Test func rejectsCountsTooLongToBeReal() {
        #expect(NumberInput.count("999999999") == 999_999_999)
        #expect(NumberInput.count("9223372036854775807") == nil)
    }
}

