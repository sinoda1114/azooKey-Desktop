import Foundation
import KanaKanjiConverterModuleWithDefaultDictionary

enum RelativeDateShortcuts {
    // 暦日の加算は最大10年程度に限定し、桁あふれや意図しない巨大な日付を避ける。
    static let maximumDaysAhead = 3660

    static func date(matching ruby: String, now: Date = Date(), calendar: Calendar = .current) -> Date? {
        let today = calendar.startOfDay(for: now)
        if ruby == "ゲツマツ" {
            guard let month = calendar.dateInterval(of: .month, for: today) else {
                return nil
            }
            return calendar.date(byAdding: .day, value: -1, to: month.end)
        }
        let prefix = "ライシュウノ"
        if ruby.hasPrefix(prefix) {
            let weekdayReading = String(ruby.dropFirst(prefix.count))
            let weekdays = ["ゲツヨウ", "カヨウ", "スイヨウ", "モクヨウ", "キンヨウ", "ドヨウ", "ニチヨウ"]
            guard let weekday = weekdays.firstIndex(where: { weekdayReading == $0 || weekdayReading == $0 + "ビ" }) else {
                return nil
            }
            // Calendar.firstWeekday（地域設定）によらず、月曜を週の始まりとする。
            let daysSinceMonday = (calendar.component(.weekday, from: today) + 5) % 7
            return calendar.date(byAdding: .day, value: 7 - daysSinceMonday + weekday, to: today)
        }
        guard let days = daysAhead(matching: ruby) else {
            return nil
        }
        return calendar.date(byAdding: .day, value: days, to: today)
    }

    private static func daysAhead(matching ruby: String) -> Int? {
        let suffix = "ニチゴ"
        guard ruby.hasSuffix(suffix) else {
            return nil
        }
        let digits = ruby.dropLast(suffix.count).unicodeScalars
        guard !digits.isEmpty, digits.count <= 4 else {
            return nil
        }
        var days = 0
        for scalar in digits {
            let value: UInt32
            switch scalar.value {
            case 0x30...0x39: value = scalar.value - 0x30
            case 0xFF10...0xFF19: value = scalar.value - 0xFF10
            default: return nil
            }
            days = days * 10 + Int(value)
        }
        guard days <= maximumDaysAhead else {
            return nil
        }
        return days
    }

    private struct Format {
        let pattern: String
        let value: PValue
        let calendar: Calendar.Identifier
    }

    static func candidates(matching ruby: String, now: Date = Date(), calendar: Calendar = .current) -> [DicdataElement] {
        guard let date = date(matching: ruby, now: now, calendar: calendar) else {
            return []
        }
        let formats: [Format] = [
            .init(pattern: "M/d", value: -18, calendar: .gregorian),
            .init(pattern: "yyyy/MM/dd", value: -18.1, calendar: .gregorian),
            .init(pattern: "yyyy-MM-dd", value: -18.2, calendar: .gregorian),
            .init(pattern: "M月d日（E）", value: -18.3, calendar: .gregorian),
            .init(pattern: "yyyy年M月d日", value: -18.4, calendar: .gregorian),
            .init(pattern: "Gyyyy年M月d日", value: -18.5, calendar: .japanese),
            .init(pattern: "E曜日", value: -18.6, calendar: .gregorian)
        ]
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "ja_JP")
        formatter.timeZone = calendar.timeZone
        return formats.map { format in
            formatter.calendar = Calendar(identifier: format.calendar)
            formatter.dateFormat = format.pattern
            return DicdataElement(word: formatter.string(from: date), ruby: ruby, cid: CIDData.固有名詞.cid, mid: MIDData.一般.mid, value: format.value)
        }
    }
}
