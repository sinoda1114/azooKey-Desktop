import Core
import Foundation
import KanaKanjiConverterModuleWithDefaultDictionary
import Testing

@MainActor
@Suite("Standalone half-width long vowel mark conversion")
struct SegmentsManagerLongVowelMarkTests {
    private func withManager(
        enabled: Bool = true,
        live: Bool,
        body: (SegmentsManager) throws -> Void
    ) throws {
        let directory = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: directory) }
        let manager = SegmentsManager(
            kanaKanjiConverter: .withDefaultDictionary(), applicationDirectoryURL: directory, containerURL: nil,
            context: .init(useZenzai: false, liveConversionEnabled: live, typeHalfWidthLongVowelMark: enabled)
        )
        try body(manager)
    }

    private func input(_ text: String, manager: SegmentsManager, style: InputStyle = .roman2kana) {
        for character in text {
            let event = KeyEventCore(
                modifierFlags: [], characters: String(character), charactersIgnoringModifiers: String(character), keyCode: 27
            )
            if case .input(let pieces) = UserAction.getUserAction(eventCore: event, inputLanguage: .japanese) {
                manager.insertAtCursorPosition(pieces: pieces, inputStyle: style)
            } else {
                Issue.record("Expected a text input action")
            }
        }
    }

    private func marked(_ manager: SegmentsManager, state: InputState = .composing) -> String {
        manager.getCurrentMarkedText(inputState: state).map(\.content).joined()
    }

    private func route(_ action: UserAction, state: InputState = .composing, live: Bool) -> (ClientAction, ClientActionCallback) {
        state.event(
            eventCore: .init(modifierFlags: [], characters: nil, charactersIgnoringModifiers: nil, keyCode: 0),
            userAction: action, inputLanguage: .japanese, liveConversionEnabled: live,
            enableDebugWindow: false, enableSuggestion: false
        )
    }

    private func candidates(_ manager: SegmentsManager) throws -> [Candidate] {
        manager.requestSetCandidateWindowState(visible: true)
        guard case .selecting(let candidates, _) = manager.getCurrentCandidateWindow(inputState: .selecting) else {
            Issue.record("Expected conversion candidate selection")
            return []
        }
        return candidates
    }

    @Test(arguments: [false, true])
    func inputStaysMarkedUntilEnter(live: Bool) throws {
        try withManager(live: live) { manager in
            let (action, callback) = route(.input([.character("ー")]), state: .none, live: live)
            guard case .appendPieceToMarkedText = action, case .transition(.composing) = callback else {
                Issue.record("Input must start composition instead of committing immediately")
                return
            }
            input("-", manager: manager)
            #expect(!manager.isEmpty)
            #expect(manager.convertTarget == "ー")
            #expect(marked(manager) == "ｰ")
            if live {
                guard case .hidden = manager.getCurrentCandidateWindow(inputState: .composing) else {
                    Issue.record("Live conversion must keep the composing candidate window hidden")
                    return
                }
            } else {
                guard case .composing(let candidates, _) = manager.getCurrentCandidateWindow(inputState: .composing) else {
                    Issue.record("Non-live conversion must expose the composing candidate")
                    return
                }
                #expect(candidates.first?.text == "ｰ")
            }
            let (enter, transition) = route(.enter, live: live)
            guard case .commitMarkedText = enter, case .transition(.none) = transition else {
                Issue.record("Enter must commit the existing marked text")
                return
            }
            #expect(manager.commitMarkedText(inputState: .composing) == "ｰ")
            #expect(manager.isEmpty)
        }
    }

    @Test(arguments: [false, true], ["ｰ", "ー"])
    func spaceAllowsBothWidthsAndEnterCommitsSelection(live: Bool, selectedText: String) throws {
        try withManager(live: live) { manager in
            input("-", manager: manager)
            let (space, transition) = route(.space(prefersFullWidthWhenInput: false), live: live)
            if live {
                guard case .enterCandidateSelectionMode = space, case .transition(.selecting) = transition else {
                    Issue.record("Live Space must enter candidate selection")
                    return
                }
            } else {
                guard case .enterFirstCandidatePreviewMode = space, case .transition(.previewing) = transition else {
                    Issue.record("Non-live Space must preview the first candidate")
                    return
                }
                manager.insertCompositionSeparator(inputStyle: .roman2kana)
                manager.requestSetCandidateWindowState(visible: false)
                #expect(marked(manager, state: .previewing) == "ｰ")
                let (nextSpace, nextTransition) = route(.space(prefersFullWidthWhenInput: false), state: .previewing, live: live)
                guard case .enterCandidateSelectionMode = nextSpace, case .transition(.selecting) = nextTransition else {
                    Issue.record("The second Space must enter candidate selection")
                    return
                }
            }
            manager.insertCompositionSeparator(inputStyle: .roman2kana, skipUpdate: true)
            manager.update(requestRichCandidates: true)
            let choices = try candidates(manager)
            #expect(Array(choices.prefix(2).map(\.text)) == ["ｰ", "ー"])
            let row = try #require(choices.firstIndex { $0.text == selectedText })
            manager.requestSelectingRow(row)
            #expect(marked(manager, state: .selecting) == selectedText)
            let selected = try #require(manager.selectedCandidate)
            #expect(selected.data.map(\.ruby).joined() == "ー")
            #expect(!selected.isLearningTarget)
            let (enter, _) = route(.enter, state: .selecting, live: live)
            guard case .submitSelectedCandidate = enter else {
                Issue.record("Enter in selection must submit the selected candidate")
                return
            }
            manager.prefixCandidateCommited(selected, leftSideContext: "")
            #expect(selected.text == selectedText)
            #expect(manager.isEmpty)
        }
    }

    @Test func nonLivePreviewEnterCommitsHalfWidth() throws {
        try withManager(live: false) { manager in
            input("-", manager: manager)
            manager.insertCompositionSeparator(inputStyle: .roman2kana)
            manager.requestSetCandidateWindowState(visible: false)
            #expect(!manager.isEmpty)
            #expect(marked(manager, state: .previewing) == "ｰ")
            let (enter, transition) = route(.enter, state: .previewing, live: false)
            guard case .commitMarkedText = enter, case .transition(.none) = transition else {
                Issue.record("Preview Enter must commit marked text")
                return
            }
            #expect(manager.commitMarkedText(inputState: .previewing) == "ｰ")
            #expect(manager.isEmpty)
        }
    }

    @Test(arguments: [false, true])
    func escapeFromSelectionKeepsTheReadingUncommitted(live: Bool) throws {
        try withManager(live: live) { manager in
            input("-", manager: manager)
            manager.update(requestRichCandidates: true)
            _ = try candidates(manager)
            manager.requestSelectingRow(1)
            #expect(marked(manager, state: .selecting) == "ー")
            let (escape, transition) = route(.escape, state: .selecting, live: live)
            if live {
                guard case .hideCandidateWindow = escape, case .transition(.composing) = transition else {
                    Issue.record("Escape must leave live selection")
                    return
                }
                manager.requestSetCandidateWindowState(visible: false)
                #expect(marked(manager) == "ｰ")
            } else {
                guard case .enterFirstCandidatePreviewMode = escape, case .transition(.previewing) = transition else {
                    Issue.record("Escape must return non-live selection to preview")
                    return
                }
                manager.insertCompositionSeparator(inputStyle: .roman2kana)
                manager.requestSetCandidateWindowState(visible: false)
                #expect(marked(manager, state: .previewing) == "ｰ")
            }
            #expect(!manager.isEmpty)
            #expect(manager.convertTarget == "ー")
        }
    }

    @Test(arguments: [false, true])
    func repeatedUpdatesDoNotDuplicatePreferredCandidates(live: Bool) throws {
        try withManager(live: live) { manager in
            input("-", manager: manager)
            for rich in [false, true, true, false] {
                manager.update(requestRichCandidates: rich)
                let choices = try candidates(manager)
                #expect(Array(choices.prefix(2).map(\.text)) == ["ｰ", "ー"])
                for width in ["ｰ", "ー"] {
                    #expect(choices.filter { $0.text == width }.count == 1)
                }
            }
        }
    }

    @Test(arguments: [false, true])
    func disabledPreservesFullWidthCompositionAndCommit(live: Bool) throws {
        try withManager(enabled: false, live: live) { manager in
            input("-", manager: manager)
            #expect(manager.convertTarget == "ー")
            #expect(marked(manager) == "ー")
            #expect(manager.commitMarkedText(inputState: .composing) == "ー")
            #expect(manager.isEmpty)
        }
    }

    @Test(arguments: [false, true])
    func backspaceAndEscapeCancelWithoutCommitting(live: Bool) throws {
        try withManager(live: live) { manager in
            input("-", manager: manager)
            let (backspace, _) = route(.backspace, live: live)
            guard case .removeLastMarkedText = backspace else {
                Issue.record("Backspace must remove marked text")
                return
            }
            manager.deleteBackwardFromCursorPosition()
            #expect(manager.isEmpty)
            #expect(marked(manager).isEmpty)
            input("-", manager: manager)
            let (escape, transition) = route(.escape, live: live)
            guard case .stopComposition = escape, case .transition(.none) = transition else {
                Issue.record("Escape must cancel composition")
                return
            }
            manager.stopComposition()
            #expect(manager.isEmpty)
            #expect(marked(manager, state: .none).isEmpty)
        }
    }

    @Test(arguments: [false, true])
    func jisKanaPhysicalHyphenRemainsHo(live: Bool) throws {
        try withManager(live: live) { manager in
            input("-", manager: manager, style: .mapped(id: .defaultKanaJIS))
            #expect(manager.convertTarget == "ほ")
            #expect(marked(manager) == "ほ")
            #expect(manager.commitMarkedText(inputState: .composing) == "ほ")
        }
    }

    @Test(arguments: [false, true], [false, true])
    func coffeeKeepsReadingAndDictionaryCandidate(live: Bool, enabled: Bool) throws {
        try withManager(enabled: enabled, live: live) { manager in
            input("ko-hi-", manager: manager)
            #expect(manager.convertTarget == "こーひー")
            #expect(!marked(manager).contains("ｰ"))
            manager.update(requestRichCandidates: true)
            let choices = try candidates(manager)
            let coffee = try #require(choices.first { $0.text == "コーヒー" })
            #expect(coffee.data.map(\.ruby).joined() == "コーヒー")
            manager.prefixCandidateCommited(coffee, leftSideContext: "")
            #expect(manager.isEmpty)
        }
    }

    @Test(arguments: [false, true])
    func appendingAndDeletingReturnsToStandalonePreference(live: Bool) throws {
        try withManager(live: live) { manager in
            input("-a", manager: manager)
            #expect(manager.convertTarget == "ーあ")
            #expect(!marked(manager).contains("ｰ"))
            manager.deleteBackwardFromCursorPosition()
            #expect(manager.convertTarget == "ー")
            #expect(marked(manager) == "ｰ")
            #expect(manager.commitMarkedText(inputState: .composing) == "ｰ")
        }
    }
}
