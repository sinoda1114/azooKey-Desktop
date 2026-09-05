enum NumericDateShortcuts {
    /// 4桁のMMDDを月日に変換する。年を指定しないため2月29日も受け付ける。
    static func monthDay(matching reading: String) -> String? {
        guard reading.unicodeScalars.count == 4 else {
            return nil
        }
        let digits = reading.unicodeScalars.compactMap { scalar -> Int? in
            switch scalar.value {
            case 0x30...0x39:
                return Int(scalar.value - 0x30)
            case 0xFF10...0xFF19:
                return Int(scalar.value - 0xFF10)
            default:
                return nil
            }
        }
        guard digits.count == 4 else {
            return nil
        }
        let month = digits[0] * 10 + digits[1]
        let day = digits[2] * 10 + digits[3]
        let monthLengths = [31, 29, 31, 30, 31, 30, 31, 31, 30, 31, 30, 31]
        guard (1...12).contains(month), (1...monthLengths[month - 1]).contains(day) else {
            return nil
        }
        return "\(digits[0])\(digits[1])/\(digits[2])\(digits[3])"
    }
}
