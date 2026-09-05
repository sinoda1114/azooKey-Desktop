import Foundation
import KanaKanjiConverterModuleWithDefaultDictionary

enum DateShortcuts {
    struct Format {
        let pattern: String
        let value: PValue
        let calendarType: DateTemplateLiteral.CalendarType
    }

    static let formats: [Format] = [
        .init(pattern: "M/d", value: -18, calendarType: .western),
        .init(pattern: "yyyy/MM/dd", value: -18.1, calendarType: .western),
        .init(pattern: "yyyy-MM-dd", value: -18.2, calendarType: .western),
        .init(pattern: "M月d日（E）", value: -18.3, calendarType: .western),
        .init(pattern: "yyyy年M月d日", value: -18.4, calendarType: .western),
        .init(pattern: "Gyyyy年M月d日", value: -18.5, calendarType: .japanese),
        .init(pattern: "E曜日", value: -18.6, calendarType: .western)
    ]

    /// Mozcと同じく、曜日だけの指定は今日を含む次の該当日（0〜6日後）として扱う。
    static func weekdays(matching ruby: String? = nil, now: Date = Date(), calendar: Calendar = .current) -> [DicdataElement] {
        let readings = ["ニチヨウ", "ゲツヨウ", "カヨウ", "スイヨウ", "モクヨウ", "キンヨウ", "ドヨウ"]
        if let ruby, !readings.contains(where: { ruby == $0 || ruby == $0 + "ビ" }) {
            return []
        }
        let today = calendar.startOfDay(for: now)
        let currentWeekday = calendar.component(.weekday, from: today)
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "ja_JP")
        formatter.timeZone = calendar.timeZone

        return readings.enumerated().flatMap { index, reading -> [DicdataElement] in
            if let ruby, ruby != reading && ruby != reading + "ビ" {
                return []
            }
            let daysAhead = (index + 1 - currentWeekday + 7) % 7
            // 秒数の加算ではなく暦日で計算し、夏時間の切り替わりにも対応する。
            guard let date = calendar.date(byAdding: .day, value: daysAhead, to: today) else {
                return []
            }
            return formats.flatMap { format -> [DicdataElement] in
                formatter.calendar = Calendar(identifier: format.calendarType.identifier)
                formatter.dateFormat = format.pattern
                let word = formatter.string(from: date)
                return [reading, reading + "ビ"].filter { ruby == nil || $0 == ruby }.map { reading in
                    DicdataElement(word: word, ruby: reading, cid: CIDData.固有名詞.cid, mid: MIDData.一般.mid, value: format.value)
                }
            }
        }
    }
}
