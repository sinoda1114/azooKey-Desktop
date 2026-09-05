enum ArrowSymbolCandidates {
    /// 日本語入力で変わる長音符・全角記号を、矢印の入力パターンとして扱う。
    static func variants(for reading: String) -> [String] {
        let normalized = String(reading.map { character -> Character in
            switch character {
            case "ー", "ｰ", "－", "−": "-"
            case "＞": ">"
            case "＜": "<"
            default: character
            }
        })
        return switch normalized {
        case "->", "-->": ["→", "⇒", "➜"]
        case "<-", "<--": ["←", "⇐", "⇦"]
        case "<->", "<-->": ["↔", "⇔"]
        default: []
        }
    }
}
