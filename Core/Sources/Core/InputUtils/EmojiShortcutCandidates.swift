/// 「えもじ」の変換で、日常的に使う感情の顔絵文字を候補に追加する。
enum EmojiShortcutCandidates {
    private static let faceEmojis = [
        "😀", "😃", "😄", "☺️", "😊", "😂", "😭", "😢", "😍", "🥰", "😉",
        "😎", "🤔", "😅", "🥺", "😤", "😡", "😱", "😇", "🙏", "👍", "👏"
    ]

    static func variants(for reading: String) -> [String] {
        reading == "エモジ" ? Self.faceEmojis : []
    }
}
