@testable import Core
import Testing

@Suite("Numeric date shortcuts")
struct NumericDateShortcutsTests {
    @Test(arguments: [
        ("0101", "01/01"), ("0201", "02/01"), ("0905", "09/05"), ("1225", "12/25")
    ])
    func convertsValidMonthDay(reading: String, expected: String) {
        #expect(NumericDateShortcuts.monthDay(matching: reading) == expected)
    }

    @Test(arguments: [
        ("0131", "01/31"), ("0229", "02/29"), ("0331", "03/31"), ("0430", "04/30"),
        ("0531", "05/31"), ("0630", "06/30"), ("0731", "07/31"), ("0831", "08/31"),
        ("0930", "09/30"), ("1031", "10/31"), ("1130", "11/30"), ("1231", "12/31")
    ])
    func acceptsEveryMonthEnd(reading: String, expected: String) {
        #expect(NumericDateShortcuts.monthDay(matching: reading) == expected)
    }

    @Test func acceptsFebruary29WithoutAYear() {
        #expect(NumericDateShortcuts.monthDay(matching: "0228") == "02/28")
        #expect(NumericDateShortcuts.monthDay(matching: "0229") == "02/29")
        #expect(NumericDateShortcuts.monthDay(matching: "0230") == nil)
    }

    @Test(arguments: [
        "0000", "0001", "0100", "1301", "9901", "0199", "0132", "0230", "0231",
        "0332", "0431", "0532", "0631", "0732", "0832", "0931", "1032", "1131", "1232"
    ])
    func rejectsInvalidMonthDay(_ reading: String) {
        #expect(NumericDateShortcuts.monthDay(matching: reading) == nil)
    }

    @Test(arguments: ["０９０５", "0９0５", "０9０5", "０９05", "09０５"])
    func normalizesFullWidthAndMixedDigits(_ reading: String) {
        #expect(NumericDateShortcuts.monthDay(matching: reading) == "09/05")
    }

    @Test(arguments: [
        "", "905", "00905", "20260905", "09/05", "09-05", " 0905", "0905 ",
        "0905\n", "\t0905", "日付0905", "0905です", "a905", "09a5", "٠٩٠٥", "۰۹۰۵",
        "०९०५", "𝟘𝟡𝟘𝟝", "⓪⑨⓪⑤", "⁰⁹⁰⁵", "〇九〇五", "０９０５️", "０９３１"
    ])
    func requiresExactlyFourSupportedDigits(_ reading: String) {
        #expect(NumericDateShortcuts.monthDay(matching: reading) == nil)
    }
}
