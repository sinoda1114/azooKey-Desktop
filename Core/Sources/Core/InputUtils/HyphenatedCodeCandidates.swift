enum HyphenatedCodeCandidates {
    /// 英数字で構成された番号・IDに、区切り文字の別表記だけを追加する。
    static func variants(for reading: String) -> [String] {
        var containsAlphanumeric = false
        var containsSeparator = false
        var halfWidthLongVowel = ""
        var asciiHyphen = ""
        for scalar in reading.unicodeScalars {
            switch scalar.value {
            case 0x30...0x39, 0x41...0x5A, 0x61...0x7A,
                 0xFF10...0xFF19, 0xFF21...0xFF3A, 0xFF41...0xFF5A:
                containsAlphanumeric = true
                halfWidthLongVowel.unicodeScalars.append(scalar)
                asciiHyphen.unicodeScalars.append(scalar)
            case 0x2D, 0xFF70, 0x30FC, 0xFF0D, 0x2212:
                containsSeparator = true
                halfWidthLongVowel.append("ｰ")
                asciiHyphen.append("-")
            default:
                return []
            }
        }
        guard containsAlphanumeric, containsSeparator else {
            return []
        }
        return [halfWidthLongVowel, asciiHyphen].filter { $0 != reading }
    }
}
