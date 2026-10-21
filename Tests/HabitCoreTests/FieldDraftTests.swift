import Testing
@testable import HabitCore

@Suite struct FieldDraftTests {
    @Test func displayingAMorePreciseValueIsNotAnEdit() {
        // 72.76 (from another client) shows as "72,8" at one decimal; viewing must not rewrite it.
        #expect(FieldDraft.change(text: "72,8", storedText: "72,8", storedValue: 72.76, parsed: 72.8) == .ignore)
    }

    @Test func typingANewValueSavesIt() {
        #expect(FieldDraft.change(text: "72,5", storedText: "72,8", storedValue: 72.8, parsed: 72.5) == .save(72.5))
        #expect(FieldDraft.change(text: "20", storedText: "", storedValue: nil, parsed: 20) == .save(20))
    }

    @Test func emptyingTheFieldClearsALoggedValue() {
        #expect(FieldDraft.change(text: "", storedText: "72,8", storedValue: 72.8, parsed: nil) == .save(nil))
        #expect(FieldDraft.change(text: "  ", storedText: "5", storedValue: 5, parsed: nil) == .save(nil))
    }

    @Test func blankTextWithNothingLoggedDoesNothing() {
        #expect(FieldDraft.change(text: "", storedText: "", storedValue: nil, parsed: nil) == .ignore)
        #expect(FieldDraft.change(text: " ", storedText: "", storedValue: nil, parsed: nil) == .ignore)
    }

    @Test func unparseableTextIsKeptButNotSaved() {
        #expect(FieldDraft.change(text: "7a", storedText: "7", storedValue: 7, parsed: nil) == .ignore)
    }

    @Test func retypingTheSameValueDoesNothing() {
        #expect(FieldDraft.change(text: "72.80", storedText: "72,8", storedValue: 72.8, parsed: 72.8) == .ignore)
    }

    @Test func replacesTextOnlyWhenItMeansSomethingElse() {
        #expect(FieldDraft.shouldShowStoredValue(parsed: 72.4, storedValue: 72.5))
        #expect(FieldDraft.shouldShowStoredValue(parsed: nil, storedValue: 0)) // Done filled a blank field
        #expect(!FieldDraft.shouldShowStoredValue(parsed: 72.5, storedValue: 72.5)) // "72." while typing
        #expect(!FieldDraft.shouldShowStoredValue(parsed: nil, storedValue: nil)) // invalid text stays put
    }
}
