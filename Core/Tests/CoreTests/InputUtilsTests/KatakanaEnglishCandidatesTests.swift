@testable import Core
import Foundation
import KanaKanjiConverterModuleWithDefaultDictionary
import Testing

struct KatakanaEnglishCandidatesTests {
    @Test func returnsLowercaseAndSentenceCaseVariants() {
        #expect(KatakanaEnglishCandidates.variants(for: "セキュリティ") == ["security", "Security"])
        #expect(KatakanaEnglishCandidates.variants(for: "ディスプレイ").starts(with: ["display", "Display"]))
        #expect(KatakanaEnglishCandidates.variants(for: "スマートフォン") == ["smartphone", "Smartphone"])
        #expect(KatakanaEnglishCandidates.variants(for: "ベッド") == ["bed", "Bed"])
        #expect(KatakanaEnglishCandidates.variants(for: "マウス") == ["mouse", "Mouse"])
        #expect(KatakanaEnglishCandidates.variants(for: "キーボード") == ["keyboard", "Keyboard"])
        #expect(KatakanaEnglishCandidates.variants(for: "メール").starts(with: ["email", "Email"]))
    }

    @Test func doesNotGuessUnknownKatakanaWords() {
        #expect(KatakanaEnglishCandidates.variants(for: "アズーキー").isEmpty)
    }

    @Test func addsCommonDictionaryWordsAfterCuratedWords() {
        #expect(KatakanaEnglishCandidates.variants(for: "アーキテクチャ") == ["architecture", "Architecture"])
        #expect(KatakanaEnglishCandidates.variants(for: "コンセント").starts(with: [
            "power outlet", "Power outlet", "electrical outlet", "Electrical outlet"
        ]))
        #expect(!KatakanaEnglishCandidates.variants(for: "コンセント").contains("consent"))
    }

    @MainActor @Test func insertsEnglishSpellingIntoConversionCandidates() {
        let manager = SegmentsManager(
            kanaKanjiConverter: .withDefaultDictionary(),
            applicationDirectoryURL: URL(fileURLWithPath: NSTemporaryDirectory(), isDirectory: true),
            containerURL: nil,
            context: .init(useZenzai: false)
        )
        manager.insertAtCursorPosition("セキュリティ", inputStyle: .direct)
        manager.requestSetCandidateWindowState(visible: true)

        switch manager.getCurrentCandidateWindow(inputState: .selecting) {
        case .selecting(let candidates, _):
            let texts = candidates.map(\.text)
            #expect(texts.contains("security"))
            #expect(texts.contains("Security"))
        case .hidden, .composing:
            Issue.record("Expected conversion candidates.")
        }
    }
}
