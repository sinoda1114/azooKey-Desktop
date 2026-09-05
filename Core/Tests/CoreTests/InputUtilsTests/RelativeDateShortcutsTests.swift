@testable import Core
import Foundation
import KanaKanjiConverterModuleWithDefaultDictionary
import Testing

@Suite("Relative date shortcuts")
struct RelativeDateShortcutsTests {
    private func calendar(_ zone: String = "Asia/Tokyo") -> Calendar {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(identifier: zone)!
        return calendar
    }

    private func date(_ year: Int, _ month: Int, _ day: Int, hour: Int = 12, calendar: Calendar) -> Date {
        calendar.date(from: DateComponents(year: year, month: month, day: day, hour: hour))!
    }

    @Test func nextWeekStartsOnMondayForEveryCurrentWeekday() {
        var calendar = calendar()
        calendar.firstWeekday = 1
        let readings = ["ゲツヨウ", "カヨウ", "スイヨウ", "モクヨウ", "キンヨウ", "ドヨウ", "ニチヨウ"]
        for currentDay in 7...13 {
            let now = date(2026, 9, currentDay, calendar: calendar)
            for (index, reading) in readings.enumerated() {
                for suffix in ["", "ビ"] {
                    let actual = RelativeDateShortcuts.date(matching: "ライシュウノ" + reading + suffix, now: now, calendar: calendar)
                    #expect(actual == date(2026, 9, 14 + index, hour: 0, calendar: calendar))
                }
            }
        }
    }

    @Test(arguments: [(2026, 2, 15, 28), (2028, 2, 15, 29), (2026, 4, 30, 30), (2026, 12, 31, 31)])
    func monthEnd(year: Int, month: Int, day: Int, lastDay: Int) {
        let calendar = calendar()
        let actual = RelativeDateShortcuts.date(matching: "ゲツマツ", now: date(year, month, day, calendar: calendar), calendar: calendar)
        #expect(actual == date(year, month, lastDay, hour: 0, calendar: calendar))
    }

    @Test func dayOffsets() {
        let cases = [
            (2026, 9, 30, "3ニチゴ", 2026, 10, 3),
            (2026, 12, 31, "１ニチゴ", 2027, 1, 1),
            (2028, 2, 28, "1ニチゴ", 2028, 2, 29),
            (2026, 9, 5, "0ニチゴ", 2026, 9, 5),
            (2026, 9, 5, "０1ニチゴ", 2026, 9, 6),
            (2026, 9, 5, "０００３ニチゴ", 2026, 9, 8)
        ]
        let calendar = calendar()
        for (year, month, day, reading, targetYear, targetMonth, targetDay) in cases {
            let actual = RelativeDateShortcuts.date(matching: reading, now: date(year, month, day, calendar: calendar), calendar: calendar)
            #expect(actual == date(targetYear, targetMonth, targetDay, hour: 0, calendar: calendar))
        }
    }

    @Test func maximumOffsetAndYearBoundary() {
        let calendar = calendar()
        let now = date(2026, 12, 31, calendar: calendar)
        #expect(RelativeDateShortcuts.date(matching: "3660ニチゴ", now: now, calendar: calendar) == calendar.date(byAdding: .day, value: 3660, to: calendar.startOfDay(for: now)))
        #expect(RelativeDateShortcuts.date(matching: "ライシュウノゲツヨウ", now: now, calendar: calendar) == date(2027, 1, 4, hour: 0, calendar: calendar))
    }

    @Test(arguments: [(2026, 3, 7, 9), (2026, 10, 31, 2)])
    func daylightSaving(year: Int, month: Int, day: Int, targetDay: Int) {
        let calendar = calendar("America/Los_Angeles")
        let now = date(year, month, day, hour: 23, calendar: calendar)
        let targetMonth = month == 10 ? 11 : month
        let target = date(year, targetMonth, targetDay, hour: 0, calendar: calendar)
        #expect(RelativeDateShortcuts.date(matching: "2ニチゴ", now: now, calendar: calendar) == target)
        #expect(RelativeDateShortcuts.date(matching: "ライシュウノゲツヨウ", now: now, calendar: calendar) == target)
    }

    @Test func sevenExistingFormats() {
        let calendar = calendar()
        let elements = RelativeDateShortcuts.candidates(matching: "3ニチゴ", now: date(2026, 9, 5, calendar: calendar), calendar: calendar)
        #expect(elements.map(\.word) == ["9/8", "2026/09/08", "2026-09-08", "9月8日（火）", "2026年9月8日", "令和8年9月8日", "火曜日"])
        #expect(elements.allSatisfy { $0.ruby == "3ニチゴ" })
    }

    @Test(arguments: ["", "ゲツヨウ", "ゲツヨウビ", "キョウ", "ライシュウ", "ライシュウノゲツ", "ライシュウノゲツヨウニ", "ゲツマツニ", "ニチゴ", "-1ニチゴ", "+1ニチゴ", "1.5ニチゴ", "٣ニチゴ", "③ニチゴ", "三ニチゴ", "3661ニチゴ", "999999999999ニチゴ", "00001ニチゴ", "3ニチゴニ", "アト3ニチゴ"])
    func requiresWholeSupportedReading(_ reading: String) {
        #expect(RelativeDateShortcuts.candidates(matching: reading).isEmpty)
    }

    @MainActor
    @Test(arguments: ["らいしゅうのげつよう", "らいしゅうのにちようび", "げつまつ", "3にちご", "３にちご"])
    func dateCanCommitWholeInput(_ reading: String) throws {
        try verifyWholeInput(reading, inputStyle: .direct)
    }

    @MainActor
    @Test(arguments: ["raishuunogetsuyou", "getsumatsu", "3nichigo"])
    func romanDateCanCommitWholeInput(_ input: String) throws {
        try verifyWholeInput(input, inputStyle: .roman2kana)
    }

    @MainActor
    @Test(arguments: ["げつまつ", "らいしゅうのげつよう", "3にちご"])
    func shortenedSegmentDoesNotOfferWholeInputDate(_ reading: String) throws {
        let directory = URL(fileURLWithPath: NSTemporaryDirectory()).appendingPathComponent(UUID().uuidString)
        defer { try? FileManager.default.removeItem(at: directory) }
        let manager = SegmentsManager(
            kanaKanjiConverter: .withDefaultDictionary(), applicationDirectoryURL: directory,
            containerURL: nil, context: .init(useZenzai: false)
        )
        manager.insertAtCursorPosition(reading, inputStyle: .direct)
        manager.editSegment(count: -1)
        for rich in [false, true] {
            manager.update(requestRichCandidates: rich)
            manager.requestSetCandidateWindowState(visible: true)
            guard case .selecting(let candidates, _) = manager.getCurrentCandidateWindow(inputState: .selecting) else {
                Issue.record("Expected selecting state")
                return
            }
            #expect(!candidates.contains { $0.text.range(of: #"^\d{4}/\d{2}/\d{2}$"#, options: .regularExpression) != nil })
        }
        manager.editSegment(count: reading.count)
        manager.update(requestRichCandidates: true)
        guard case .selecting(let candidates, _) = manager.getCurrentCandidateWindow(inputState: .selecting) else {
            Issue.record("Expected selecting state")
            return
        }
        let candidate = try #require(candidates.first { $0.text.range(of: #"^\d{4}/\d{2}/\d{2}$"#, options: .regularExpression) != nil })
        manager.prefixCandidateCommited(candidate, leftSideContext: "")
        #expect(manager.isEmpty)
    }

    @MainActor
    private func verifyWholeInput(_ input: String, inputStyle: InputStyle) throws {
        let directory = URL(fileURLWithPath: NSTemporaryDirectory()).appendingPathComponent(UUID().uuidString)
        defer { try? FileManager.default.removeItem(at: directory) }
        let manager = SegmentsManager(
            kanaKanjiConverter: .withDefaultDictionary(), applicationDirectoryURL: directory,
            containerURL: nil, context: .init(useZenzai: false)
        )
        manager.insertAtCursorPosition(input, inputStyle: inputStyle)
        for rich in [false, true] {
            manager.update(requestRichCandidates: rich)
            manager.requestSetCandidateWindowState(visible: true)
            guard case .selecting(let candidates, _) = manager.getCurrentCandidateWindow(inputState: .selecting) else {
                Issue.record("Expected selecting state")
                return
            }
            let candidate = try #require(candidates.first { $0.text.range(of: #"^\d{4}/\d{2}/\d{2}$"#, options: .regularExpression) != nil })
            #expect(!candidate.isLearningTarget)
            #expect(candidates.contains { $0.text.range(of: "[年月日/曜日-]", options: .regularExpression) == nil })
            #expect(candidates.filter { $0.text == candidate.text }.count == 1)
            if rich {
                manager.prefixCandidateCommited(candidate, leftSideContext: "")
                #expect(manager.isEmpty)
            }
        }
    }
}
