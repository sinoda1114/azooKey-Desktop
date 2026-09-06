@testable import Core
import Foundation
import KanaKanjiConverterModuleWithDefaultDictionary
import Testing

@MainActor
struct EmojiShortcutCandidatesTests {
    @Test func returnsCommonFaceEmojisForEmojiReading() {
        #expect(EmojiShortcutCandidates.variants(for: "エモジ") == [
            "😀", "😃", "😄", "☺️", "😊", "😂", "😭", "😢", "😍", "🥰", "😉",
            "😎", "🤔", "😅", "🥺", "😤", "😡", "😱", "😇", "🙏", "👍", "👏"
        ])
        #expect(EmojiShortcutCandidates.variants(for: "エモーティコン").isEmpty)
    }

    @Test func insertsFaceEmojisIntoConversionCandidates() {
        let manager = SegmentsManager(
            kanaKanjiConverter: .withDefaultDictionary(),
            applicationDirectoryURL: URL(fileURLWithPath: NSTemporaryDirectory(), isDirectory: true),
            containerURL: nil,
            context: .init(useZenzai: false)
        )
        manager.insertAtCursorPosition("えもじ", inputStyle: .direct)
        manager.requestSetCandidateWindowState(visible: true)

        switch manager.getCurrentCandidateWindow(inputState: .selecting) {
        case .selecting(let candidates, _):
            let texts = candidates.map(\.text)
            #expect(texts.contains("😀"))
            #expect(texts.contains("😭"))
            #expect(texts.contains("🙏"))
        case .hidden, .composing:
            Issue.record("Expected conversion candidates.")
        }
    }
}
