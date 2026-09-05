@testable import Core
import Foundation
import KanaKanjiConverterModuleWithDefaultDictionary
import Testing

@MainActor
struct ArrowSymbolCandidatesTests {
    @Test func patterns() {
        for input in ["ー＞", "ｰ>", "->", "－＞", "−>", "ーー＞"] {
            #expect(ArrowSymbolCandidates.variants(for: input) == ["→", "⇒", "➜"])
        }
        #expect(ArrowSymbolCandidates.variants(for: "＜ー") == ["←", "⇐", "⇦"])
        #expect(ArrowSymbolCandidates.variants(for: "＜ー＞") == ["↔", "⇔"])
        for input in ["", "ー", ">", "a->b", "コーヒー＞", "<=", "ー ＞"] {
            #expect(ArrowSymbolCandidates.variants(for: input).isEmpty)
        }
    }

    @Test(arguments: ["→", "⇒", "➜"])
    func convertAndCommit(expected: String) throws {
        try withManager { manager in
            manager.insertAtCursorPosition("ー＞", inputStyle: .direct)
            for rich in [false, true] {
                manager.update(requestRichCandidates: rich)
                manager.requestSetCandidateWindowState(visible: true)
                guard case .selecting(let choices, _) = manager.getCurrentCandidateWindow(inputState: .selecting) else {
                    Issue.record("Expected arrow candidates")
                    return
                }
                #expect(choices.filter { $0.text == expected }.count == 1)
                #expect(choices.contains { $0.text == "ー＞" })
                if rich {
                    let candidate = try #require(choices.first { $0.text == expected })
                    manager.prefixCandidateCommited(candidate, leftSideContext: "")
                    #expect(manager.isEmpty)
                }
            }
        }
    }

    @Test func editedPrefixPreservesSuffix() throws {
        try withManager { manager in
            manager.insertAtCursorPosition("ー＞あ", inputStyle: .direct)
            manager.editSegment(count: -1)
            guard case .selecting(let choices, _) = manager.getCurrentCandidateWindow(inputState: .selecting) else {
                Issue.record("Expected edited candidates")
                return
            }
            let candidate = try #require(choices.first { $0.text == "⇒" })
            manager.prefixCandidateCommited(candidate, leftSideContext: "")
            #expect(manager.convertTarget == "あ")
        }
    }

    private func withManager(_ body: (SegmentsManager) throws -> Void) throws {
        let directory = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: directory) }
        let manager = SegmentsManager(kanaKanjiConverter: .withDefaultDictionary(), applicationDirectoryURL: directory,
                                      containerURL: nil, context: .init(useZenzai: false))
        try body(manager)
    }
}
