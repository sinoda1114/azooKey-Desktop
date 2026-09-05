@testable import Core
import Foundation
import KanaKanjiConverterModuleWithDefaultDictionary
import Testing

@Suite("Weekday date shortcuts")
struct DateShortcutsTests {
    private func calendar(_ zone: String = "Asia/Tokyo") -> Calendar {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(identifier: zone)!
        return calendar
    }

    private func date(_ year: Int, _ month: Int, _ day: Int, hour: Int = 12, calendar: Calendar) -> Date {
        calendar.date(from: DateComponents(year: year, month: month, day: day, hour: hour))!
    }

    @Test func allWeekdaysAndBothReadings() {
        let calendar = calendar()
        let shortcuts = DateShortcuts.weekdays(now: date(2026, 9, 5, calendar: calendar), calendar: calendar)
        let expected = [
            ("ニチヨウ", "2026/09/06"), ("ゲツヨウ", "2026/09/07"),
            ("カヨウ", "2026/09/08"), ("スイヨウ", "2026/09/09"),
            ("モクヨウ", "2026/09/10"), ("キンヨウ", "2026/09/11"),
            ("ドヨウ", "2026/09/05")
        ]
        for (reading, text) in expected {
            for ruby in [reading, reading + "ビ"] {
                #expect(shortcuts.contains { $0.ruby == ruby && $0.word == text })
            }
        }
    }

    @Test func existingDateFormats() {
        let calendar = calendar()
        let shortcuts = DateShortcuts.weekdays(now: date(2026, 9, 5, calendar: calendar), calendar: calendar)
        let words = Set(shortcuts.filter { $0.ruby == "ゲツヨウ" }.map(\.word))
        #expect(words == Set(["9/7", "2026/09/07", "2026-09-07", "9月7日（月）", "2026年9月7日", "令和8年9月7日", "月曜日"]))
    }

    @Test(arguments: [
        (2026, 9, 30, "ゲツヨウ", "2026/10/05"),
        (2026, 12, 31, "ゲツヨウ", "2027/01/04"),
        (2028, 2, 28, "カヨウ", "2028/02/29")
    ])
    func calendarBoundaries(year: Int, month: Int, day: Int, reading: String, expected: String) {
        let calendar = calendar()
        let shortcuts = DateShortcuts.weekdays(now: date(year, month, day, calendar: calendar), calendar: calendar)
        #expect(shortcuts.contains { $0.ruby == reading && $0.word == expected })
    }

    @Test func refreshesAfterMidnight() {
        let calendar = calendar()
        let monday = DateShortcuts.weekdays(now: date(2026, 9, 7, hour: 23, calendar: calendar), calendar: calendar)
        let tuesday = DateShortcuts.weekdays(now: date(2026, 9, 8, hour: 0, calendar: calendar), calendar: calendar)
        #expect(monday.contains { $0.ruby == "ゲツヨウ" && $0.word == "2026/09/07" })
        #expect(tuesday.contains { $0.ruby == "ゲツヨウ" && $0.word == "2026/09/14" })
    }

    @Test(arguments: [(2026, 3, 7, "2026/03/09"), (2026, 10, 31, "2026/11/02")])
    func daylightSaving(year: Int, month: Int, day: Int, expected: String) {
        let calendar = calendar("America/Los_Angeles")
        let shortcuts = DateShortcuts.weekdays(now: date(year, month, day, hour: 23, calendar: calendar), calendar: calendar)
        #expect(shortcuts.contains { $0.ruby == "ゲツヨウ" && $0.word == expected })
    }

    @Test func usesLocalDay() {
        let tokyo = calendar()
        let losAngeles = calendar("America/Los_Angeles")
        let now = date(2026, 9, 8, hour: 0, calendar: tokyo)
        let shortcuts = DateShortcuts.weekdays(now: now, calendar: losAngeles)
        #expect(shortcuts.contains { $0.ruby == "ゲツヨウ" && $0.word == "2026/09/07" })
    }

    @Test(arguments: ["", "ゲツ", "ゲツヨウニアイマショウ", "ライシュウノゲツヨウ", "キョウ"])
    func requiresWholeWeekdayReading(_ ruby: String) {
        #expect(DateShortcuts.weekdays(matching: ruby).isEmpty)
    }

    @MainActor
    @Test(arguments: ["getsuyou", "getsuyoubi", "kayou", "kayoubi"])
    func romanInputCanCommitTheWholeDate(_ input: String) throws {
        let manager = SegmentsManager(
            kanaKanjiConverter: .withDefaultDictionary(),
            applicationDirectoryURL: URL(fileURLWithPath: NSTemporaryDirectory(), isDirectory: true),
            containerURL: nil,
            context: .init(useZenzai: false)
        )
        manager.insertAtCursorPosition(input, inputStyle: .roman2kana)
        manager.update(requestRichCandidates: true)
        manager.requestSetCandidateWindowState(visible: true)
        guard case .selecting(let candidates, _) = manager.getCurrentCandidateWindow(inputState: .selecting) else {
            Issue.record("Expected selecting state")
            return
        }
        let candidate = try #require(candidates.first { $0.text.range(of: #"^\d{4}/\d{2}/\d{2}$"#, options: .regularExpression) != nil })
        #expect(!candidate.isLearningTarget)
        manager.prefixCandidateCommited(candidate, leftSideContext: "")
        #expect(manager.isEmpty)
    }

    @MainActor
    @Test(arguments: ["にちよう", "にちようび", "げつよう", "げつようび", "かよう", "かようび", "すいよう", "すいようび", "もくよう", "もくようび", "きんよう", "きんようび", "どよう", "どようび"])
    func appearsInConversionCandidates(_ reading: String) throws {
        let manager = SegmentsManager(
            kanaKanjiConverter: .withDefaultDictionary(),
            applicationDirectoryURL: URL(fileURLWithPath: NSTemporaryDirectory(), isDirectory: true),
            containerURL: nil,
            context: .init(useZenzai: false)
        )
        manager.insertAtCursorPosition(reading, inputStyle: .direct)
        manager.update(requestRichCandidates: true)
        manager.requestSetCandidateWindowState(visible: true)
        switch manager.getCurrentCandidateWindow(inputState: .selecting) {
        case .selecting(let candidates, _):
            #expect(candidates.contains { $0.text.range(of: #"^\d{4}/\d{2}/\d{2}$"#, options: .regularExpression) != nil }, "Candidates: \(candidates.map(\.text))")
        case .hidden, .composing:
            Issue.record("Expected date candidates in the selection window")
        }
    }
}
