@testable import Core
import Foundation
import KanaKanjiConverterModuleWithDefaultDictionary
import Testing

@MainActor
struct NumericSeparatorCandidatesTests {
    @Test func numericGroupsAndStandaloneMiddleDot() {
        #expect(NumericSeparatorCandidates.variants(for: "5。1") == ["5.1"])
        #expect(NumericSeparatorCandidates.variants(for: "５。１") == ["5.1"])
        #expect(NumericSeparatorCandidates.variants(for: "10・10") == ["10/10"])
        #expect(NumericSeparatorCandidates.variants(for: "２０２６・9・05") == ["2026/9/05"])
        #expect(NumericSeparatorCandidates.variants(for: "1。2。3") == ["1.2.3"])
        #expect(NumericSeparatorCandidates.variants(for: "・") == ["/", "／"])
        for input in ["", "。", "5。", "。1", "10・・10", "1。2・3", "文章。", "名前・名前", "10/10", "5.1", "１０", "5 。1"] {
            #expect(NumericSeparatorCandidates.variants(for: input).isEmpty)
        }
    }

    @Test(arguments: [("5。1", "5.1"), ("10・10", "10/10"), ("・", "/"), ("・", "／"), ("５。１", "5.1")])
    func candidatesPreserveInputAndCommitWholeValue(input: String, expected: String) throws {
        let directory = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: directory) }
        let manager = SegmentsManager(kanaKanjiConverter: .withDefaultDictionary(), applicationDirectoryURL: directory,
                                      containerURL: nil, context: .init(useZenzai: false))
        manager.insertAtCursorPosition(input, inputStyle: .direct)
        for rich in [false, true] {
            manager.update(requestRichCandidates: rich)
            manager.requestSetCandidateWindowState(visible: true)
            guard case .selecting(let choices, _) = manager.getCurrentCandidateWindow(inputState: .selecting) else {
                Issue.record("Expected conversion candidates")
                return
            }
            #expect(manager.convertTarget == input)
            #expect(choices.contains { $0.text == input })
            #expect(choices.filter { $0.text == expected }.count == 1)
            if rich {
                let row = try #require(choices.firstIndex { $0.text == expected })
                manager.requestSelectingRow(row)
                let candidate = try #require(manager.selectedCandidate)
                manager.prefixCandidateCommited(candidate, leftSideContext: "")
                #expect(manager.isEmpty)
            }
        }
    }
}
