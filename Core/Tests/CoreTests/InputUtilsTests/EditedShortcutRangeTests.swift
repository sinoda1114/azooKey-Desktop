import Core
import Foundation
import KanaKanjiConverterModuleWithDefaultDictionary
import Testing

@MainActor
@Test func wholeInputShortcutIsSuppressedForEditedSegment() throws {
    let directory = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
    try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
    defer { try? FileManager.default.removeItem(at: directory) }
    let manager = SegmentsManager(kanaKanjiConverter: .withDefaultDictionary(), applicationDirectoryURL: directory,
                                  containerURL: nil, context: .init(useZenzai: false))
    manager.insertAtCursorPosition("げつよう", inputStyle: .direct)
    manager.editSegment(count: -1)
    manager.requestSetCandidateWindowState(visible: true)
    guard case .selecting(let choices, _) = manager.getCurrentCandidateWindow(inputState: .selecting) else {
        Issue.record("Expected candidates for edited segment")
        return
    }
    #expect(!choices.contains { $0.text.contains("/") || $0.text.contains("月") && $0.text.contains("日") })
    #expect(manager.convertTarget == "げつよう")
}
