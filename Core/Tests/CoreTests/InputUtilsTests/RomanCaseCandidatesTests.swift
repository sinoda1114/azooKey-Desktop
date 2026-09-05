@testable import Core
import Foundation
import KanaKanjiConverterModuleWithDefaultDictionary
import Testing

@MainActor
struct RomanCaseCandidatesTests {
    @Test func variantsAndExclusions() {
        #expect(RomanCaseCandidates.variants(for: "fable") == ["fable", "Fable", "FABLE"])
        #expect(RomanCaseCandidates.variants(for: "GitHub") == ["github", "Github", "GITHUB"])
        #expect(RomanCaseCandidates.variants(for: "a") == ["a", "A"])
        for input in ["", "1111", "ふぁbぇ", "コーヒー", "abc\ndef"] {
            #expect(RomanCaseCandidates.variants(for: input).isEmpty)
        }
    }

    @Test(arguments: ["fable", "github", "FABLE"], ["lower", "title", "upper"])
    func originalKeysCanBeConvertedAndFullyCommitted(input: String, form: String) throws {
        let directory = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: directory) }
        let manager = SegmentsManager(kanaKanjiConverter: .withDefaultDictionary(), applicationDirectoryURL: directory,
                                      containerURL: nil, context: .init(useZenzai: false))
        for character in input {
            manager.insertAtCursorPosition(String(character), inputStyle: .roman2kana)
        }
        if input == "fable" { #expect(manager.convertTarget == "ふぁbぇ") }
        let lower = input.lowercased()
        let expected = form == "lower" ? lower : form == "title" ? lower.prefix(1).uppercased() + lower.dropFirst() : input.uppercased()
        for rich in [false, true] {
            manager.update(requestRichCandidates: rich)
            manager.requestSetCandidateWindowState(visible: true)
            guard case .selecting(let choices, _) = manager.getCurrentCandidateWindow(inputState: .selecting) else {
                Issue.record("Expected conversion candidates")
                return
            }
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
