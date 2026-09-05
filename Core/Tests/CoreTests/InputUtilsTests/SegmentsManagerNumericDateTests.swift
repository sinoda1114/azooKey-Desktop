import Core
import Foundation
import KanaKanjiConverterModuleWithDefaultDictionary
import Testing

@MainActor
@Suite("Numeric month-day conversion candidates")
struct SegmentsManagerNumericDateTests {
    private func withManager(_ body: (SegmentsManager) throws -> Void) throws {
        let directory = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: directory) }
        let manager = SegmentsManager(
            kanaKanjiConverter: .withDefaultDictionary(),
            applicationDirectoryURL: directory,
            containerURL: nil,
            context: .init(useZenzai: false)
        )
        try body(manager)
    }

    private func candidates(_ manager: SegmentsManager, rich: Bool = true) -> [Candidate] {
        manager.update(requestRichCandidates: rich)
        manager.requestSetCandidateWindowState(visible: true)
        guard case .selecting(let candidates, _) = manager.getCurrentCandidateWindow(inputState: .selecting) else {
            Issue.record("Expected conversion candidate selection")
            return []
        }
        return candidates
    }

    @Test(arguments: [
        ("1111", "11/11"), ("0102", "01/02"), ("0229", "02/29"),
        ("１１１１", "11/11"), ("０１０２", "01/02"), ("０２２９", "02/29"),
        ("０1０2", "01/02")
    ])
    func validMonthDayPreservesDigitsAndCommitsTheWholeDate(input: String, expected: String) throws {
        try withManager { manager in
            manager.insertAtCursorPosition(input, inputStyle: .direct)
            #expect(manager.convertTarget == input)
            #expect(!manager.isEmpty)
            let choices = candidates(manager)
            #expect(choices.contains { $0.text == input }, "The original numeric candidate must remain available")
            #expect(choices.filter { $0.text == expected }.count == 1)
            let row = try #require(choices.firstIndex { $0.text == expected })
            manager.requestSelectingRow(row)
            let selected = try #require(manager.selectedCandidate)
            #expect(!selected.isLearningTarget)
            #expect(selected.data.map(\.ruby).joined() == input)
            #expect(manager.getCurrentMarkedText(inputState: .selecting).map(\.content).joined() == expected)
            manager.prefixCandidateCommited(selected, leftSideContext: "")
            #expect(manager.isEmpty)
            #expect(manager.convertTarget.isEmpty)
        }
    }

    @Test(arguments: ["0000", "1301", "0100", "0230", "0431", "０２３０", "111", "11111", "1111あ"])
    func invalidMonthDayDoesNotAddDateCandidates(input: String) throws {
        try withManager { manager in
            manager.insertAtCursorPosition(input, inputStyle: .direct)
            let choices = candidates(manager)
            #expect(!choices.contains {
                $0.text.range(of: #"^\d{2}/\d{2}$"#, options: .regularExpression) != nil
            }, "Invalid MMDD must not gain a date candidate")
            #expect(!manager.isEmpty)
            #expect(manager.convertTarget == input)
        }
    }

    @Test func repeatedUpdatesKeepExactlyOneDateCandidate() throws {
        try withManager { manager in
            manager.insertAtCursorPosition("1111", inputStyle: .roman2kana)
            for rich in [false, true, true, false] {
                let choices = candidates(manager, rich: rich)
                #expect(choices.filter { $0.text == "11/11" }.count == 1)
                #expect(choices.contains { $0.text == "1111" })
            }
        }
    }

    @Test func editingTheReadingRemovesAndRestoresTheDateCandidate() throws {
        try withManager { manager in
            manager.insertAtCursorPosition("1111", inputStyle: .direct)
            #expect(candidates(manager).contains { $0.text == "11/11" })
            manager.deleteBackwardFromCursorPosition()
            #expect(manager.convertTarget == "111")
            #expect(!candidates(manager).contains { $0.text == "11/11" })
            manager.insertAtCursorPosition("1", inputStyle: .direct)
            #expect(manager.convertTarget == "1111")
            #expect(candidates(manager).filter { $0.text == "11/11" }.count == 1)
        }
    }
}
