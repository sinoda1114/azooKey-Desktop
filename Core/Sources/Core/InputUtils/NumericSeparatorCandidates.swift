enum NumericSeparatorCandidates {
    /// 数字の区切りと単独の中黒に、記号の別表記を追加する。
    static func variants(for reading: String) -> [String] {
        if reading == "・" {
            return ["/", "／"]
        }
        let separator: Character
        let replacement: String
        if reading.contains("。") {
            separator = "。"
            replacement = "."
        } else if reading.contains("・") {
            separator = "・"
            replacement = "/"
        } else {
            return []
        }
        let groups = reading.split(separator: separator, omittingEmptySubsequences: false)
        var normalized: [String] = []
        for group in groups {
            guard !group.isEmpty else {
                return []
            }
            var digits = ""
            for scalar in group.unicodeScalars {
                switch scalar.value {
                case 0x30...0x39:
                    digits.unicodeScalars.append(scalar)
                case 0xFF10...0xFF19:
                    digits.unicodeScalars.append(UnicodeScalar(scalar.value - 0xFEE0)!)
                default:
                    return []
                }
            }
            normalized.append(digits)
        }
        return [normalized.joined(separator: replacement)]
    }
}
