import Core
import Foundation
import KanaKanjiConverterModuleWithDefaultDictionary
import Testing

@MainActor
struct HyphenatedCodeConversionTests {
    @Test(arguments: [false, true], [false, true])
    func postalReadingOffersHalfWidthVariants(live: Bool, enabled: Bool) throws {
        for chosen in ["457ｰ0067", "457-0067"] {
            try withManager(live: live, enabled: enabled) { manager in
                for character in "457-0067" {
                    let code: UInt16 = character == "-" ? 27 : ["4": 21, "5": 23, "7": 26, "0": 29, "6": 22][character]!
                    let action = UserAction.getUserAction(eventCore: .init(modifierFlags: [], characters: String(character), charactersIgnoringModifiers: String(character), keyCode: code), inputLanguage: .japanese)
                    switch action {
                    case .number(let number): manager.insertAtCursorPosition(pieces: [number.inputPiece], inputStyle: .roman2kana)
                    case .input(let pieces): manager.insertAtCursorPosition(pieces: pieces, inputStyle: .roman2kana)
                    default: Issue.record("Unexpected input")
                    }
                }
                #expect(manager.convertTarget == "457ー0067")
                try selectAndCommit(chosen, manager: manager)
            }
        }
    }

    @Test(arguments: [("090ー1234ー5678", "090ｰ1234ｰ5678"), ("ABー123", "ABｰ123"), ("１２３ー４５", "１２３ｰ４５")])
    func phoneNumbersAndCodesUseTheSameConversion(input: String, expected: String) throws {
        try withManager(live: false, enabled: true) { manager in
            manager.insertAtCursorPosition(input, inputStyle: .direct)
            try selectAndCommit(expected, manager: manager)
        }
    }

    private func withManager(live: Bool, enabled: Bool, body: (SegmentsManager) throws -> Void) throws {
        let directory = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: directory) }
        let manager = SegmentsManager(kanaKanjiConverter: .withDefaultDictionary(), applicationDirectoryURL: directory, containerURL: nil,
                                      context: .init(useZenzai: false, liveConversionEnabled: live, typeHalfWidthLongVowelMark: enabled))
        try body(manager)
    }

    private func selectAndCommit(_ expected: String, manager: SegmentsManager) throws {
        let original = manager.convertTarget
        for rich in [false, true] {
            manager.update(requestRichCandidates: rich)
            manager.requestSetCandidateWindowState(visible: true)
            guard case .selecting(let choices, _) = manager.getCurrentCandidateWindow(inputState: .selecting) else {
                Issue.record("Expected candidates")
                return
            }
            #expect(manager.convertTarget == original)
            #expect(choices.filter { $0.text == expected }.count == 1)
            #expect(choices.contains { $0.text == original })
            if rich {
                let row = try #require(choices.firstIndex { $0.text == expected })
                manager.requestSelectingRow(row)
                #expect(manager.getCurrentMarkedText(inputState: .selecting).map(\.content).joined() == expected)
                let candidate = try #require(manager.selectedCandidate)
                #expect(!candidate.isLearningTarget)
                manager.prefixCandidateCommited(candidate, leftSideContext: "")
                #expect(manager.isEmpty)
            }
        }
    }
}
