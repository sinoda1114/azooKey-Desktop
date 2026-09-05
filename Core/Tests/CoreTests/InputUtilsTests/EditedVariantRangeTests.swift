import Core
import Foundation
import KanaKanjiConverterModuleWithDefaultDictionary
import Testing

@MainActor
@Test func editedVariantConsumesOnlySelectedPrefix() throws {
    let directory = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
    try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
    defer { try? FileManager.default.removeItem(at: directory) }
    let manager = SegmentsManager(kanaKanjiConverter: .withDefaultDictionary(), applicationDirectoryURL: directory,
                                  containerURL: nil, context: .init(useZenzai: false))
    manager.insertAtCursorPosition("10・10", inputStyle: .direct)
    manager.editSegment(count: -1)
    manager.requestSetCandidateWindowState(visible: true)
    guard case .selecting(let choices, _) = manager.getCurrentCandidateWindow(inputState: .selecting) else {
        Issue.record("Expected candidates for edited segment")
        return
    }
    let candidate = try #require(choices.first { $0.text == "10/1" })
    manager.prefixCandidateCommited(candidate, leftSideContext: "")
    #expect(manager.convertTarget == "0")
}
