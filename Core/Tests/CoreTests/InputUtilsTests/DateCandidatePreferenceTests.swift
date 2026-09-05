@testable import Core
import Foundation
import KanaKanjiConverterModuleWithDefaultDictionary
import Testing

struct DateCandidatePreferenceTests {
    private func entry(_ word: String) -> DicdataElement {
        .init(word: word, ruby: "キョウ", cid: CIDData.固有名詞.cid, mid: MIDData.一般.mid, value: -18)
    }

    private func candidate(_ word: String) -> Candidate {
        .init(text: word, value: -18, composingCount: .surfaceCount(3), lastMid: MIDData.一般.mid,
              data: [entry(word)], isLearningTarget: false)
    }

    @Test func standardPreservesEveryCandidateAndAddsNothing() {
        let original = ["今日", "2026/09/05", "9/5", "9月5日（土）"].map(candidate)
        let result = DateCandidatePreference.applying(to: original, dateEntries: [entry("9/5")],
                                                     readingCount: 3, preference: .standard)
        #expect(result.map(\.text) == original.map(\.text))
        #expect(Config.DateFormatPreference.default == .standard)
    }

    @Test func preferenceOnlySwapsDateSlotsAndIsStable() {
        let original = ["今日", "2026/09/05", "教", "9月5日（土）", "京", "09/05", "9/5"].map(candidate)
        let words: Set<String> = ["2026/09/05", "9月5日（土）", "09/05", "9/5"]
        let result = DateCandidatePreference.reordered(original, dateWords: words, preference: .weekday)
        #expect(result.map(\.text) == ["今日", "9月5日（土）", "教", "2026/09/05", "京", "09/05", "9/5"])
        let monthDay = DateCandidatePreference.reordered(original, dateWords: words, preference: .monthDay)
        #expect(monthDay.map(\.text) == ["今日", "09/05", "教", "2026/09/05", "京", "9月5日（土）", "9/5"])
    }

    @Test func missingPaddedDateIsAddedWithoutReplacingOriginalOrDuplicates() {
        let original = ["今日", "9/5", "教"].map(candidate)
        let entries = [entry("9/5"), entry("9/5")]
        let result = DateCandidatePreference.applying(to: original, dateEntries: entries,
                                                     readingCount: 3, preference: .monthDay)
        #expect(result.map(\.text) == ["今日", "09/05", "教", "9/5"])
        #expect(result.filter { $0.text == "09/05" }.count == 1)
        #expect(result.first { $0.text == "09/05" }?.isLearningTarget == false)
        var text = ComposingText()
        text.insertAtCursorPosition("きょう", inputStyle: .direct)
        for candidate in result {
            var remaining = text
            remaining.prefixComplete(composingCount: candidate.composingCount)
            #expect(remaining.convertTarget.isEmpty)
        }
        let repeated = DateCandidatePreference.applying(to: result, dateEntries: entries,
                                                       readingCount: 3, preference: .monthDay)
        #expect(repeated.map(\.text) == result.map(\.text))
    }

    @Test func unregisteredFractionAndWeekdayWordsRemainUntouched() {
        let original = ["1/2", "土曜日", "9月5日（土）", "今日", "9/5"].map(candidate)
        let result = DateCandidatePreference.applying(to: original, dateEntries: [entry("9/5")],
                                                     readingCount: 3, preference: .monthDay)
        #expect(result.map(\.text) == ["1/2", "土曜日", "9月5日（土）", "今日", "09/05", "9/5"])
        let noDates = DateCandidatePreference.applying(to: original, dateEntries: [],
                                                      readingCount: 3, preference: .weekday)
        #expect(noDates.map(\.text) == original.map(\.text))
    }

    @Test func preferredDateCanBeRecoveredWhenEngineOmitsIt() {
        let original = ["今日", "教", "京", "強", "きょう", "キョウ"].map(candidate)
        let result = DateCandidatePreference.applying(to: original, dateEntries: [entry("9月5日（土）")],
                                                     readingCount: 3, preference: .weekday)
        #expect(result.map(\.text) == ["今日", "教", "京", "強", "きょう", "9月5日（土）", "キョウ"])
    }

    @Test(arguments: [("9/5", "09/05"), ("02/29", "02/29"), ("12/31", "12/31")])
    func validMonthDay(input: String, expected: String) {
        #expect(DateCandidatePreference.paddedMonthDay(input) == expected)
    }

    @Test(arguments: ["0/1", "13/1", "2/30", "4/31", "9/0", "2026/9/5", "９/５", "9/5です", "1/2/3"])
    func rejectsOtherFormats(input: String) {
        #expect(DateCandidatePreference.paddedMonthDay(input) == nil)
    }

    @MainActor
    @Test(arguments: [Config.DateFormatPreference.Value.monthDay, .weekday])
    func actualConversionOffersPreferredDateWithoutChangingSettings(preference: Config.DateFormatPreference.Value) throws {
        let directory = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: directory) }
        let manager = SegmentsManager(kanaKanjiConverter: .withDefaultDictionary(),
                                      applicationDirectoryURL: directory, containerURL: nil,
                                      context: .init(useZenzai: false, dateFormatPreference: preference))
        manager.insertAtCursorPosition("きょう", inputStyle: .direct)
        for rich in [false, true] {
            manager.update(requestRichCandidates: rich)
            manager.requestSetCandidateWindowState(visible: true)
            guard case .selecting(let candidates, _) = manager.getCurrentCandidateWindow(inputState: .selecting) else {
                Issue.record("候補欄が表示されません")
                return
            }
            let pattern = preference == .monthDay ? #"^[0-9]{2}/[0-9]{2}$"# : #"^[0-9]+月[0-9]+日（[日月火水木金土]）$"#
            #expect(candidates.contains { $0.text.range(of: pattern, options: .regularExpression) != nil })
            #expect(candidates.contains { $0.text == "今日" })
        }
    }

    @Test func numericInputGetsThisYearsWeekdayAndKeepsOriginal() throws {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = try #require(TimeZone(identifier: "Asia/Tokyo"))
        let now = try #require(calendar.date(from: DateComponents(year: 2026, month: 9, day: 5)))
        for ruby in ["1111", "１１１１"] {
            let dateEntry = DicdataElement(word: "11/11", ruby: ruby, cid: CIDData.固有名詞.cid, mid: MIDData.一般.mid, value: -18)
            let original = [candidate("1111"), candidate("11/11")]
            let result = DateCandidatePreference.applying(to: original, dateEntries: [dateEntry], readingCount: 4,
                                                         preference: .weekday, now: now, calendar: calendar)
            #expect(result.map(\.text) == ["1111", "11月11日（水）", "11/11"])
            let added = try #require(result.first { $0.text == "11月11日（水）" })
            #expect(!added.isLearningTarget)
            var composing = ComposingText()
            composing.insertAtCursorPosition(ruby, inputStyle: .direct)
            composing.prefixComplete(composingCount: added.composingCount)
            #expect(composing.isEmpty)
        }
    }

    @Test func numericLeapDayOnlyGetsWeekdayInLeapYear() throws {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = try #require(TimeZone(identifier: "Asia/Tokyo"))
        let entry = DicdataElement(word: "02/29", ruby: "0229", cid: CIDData.固有名詞.cid, mid: MIDData.一般.mid, value: -18)
        let commonYear = try #require(calendar.date(from: DateComponents(year: 2026, month: 1, day: 1)))
        let leapYear = try #require(calendar.date(from: DateComponents(year: 2028, month: 1, day: 1)))
        #expect(DateCandidatePreference.numericWeekday(entry, now: commonYear, calendar: calendar) == nil)
        #expect(DateCandidatePreference.numericWeekday(entry, now: leapYear, calendar: calendar) == "2月29日（火）")
        #expect(DateCandidatePreference.numericWeekday(self.entry("11/11"), now: commonYear, calendar: calendar) == nil)
    }

}
