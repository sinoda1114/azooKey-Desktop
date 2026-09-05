import Foundation
import KanaKanjiConverterModuleWithDefaultDictionary

/// 日付の生成元が明示した候補だけを並べ替える。数字や分数の見た目だけでは判定しない。
enum DateCandidatePreference {
    static func apply(
        to result: inout ConversionResult,
        dateEntries: [DicdataElement],
        readingCount: Int,
        preference: Config.DateFormatPreference.Value
    ) {
        result.mainResults = applying(to: result.mainResults, dateEntries: dateEntries,
                                      readingCount: readingCount, preference: preference)
        result.firstClauseResults = reordered(result.firstClauseResults, dateWords: Set(dateEntries.map(\.word)),
                                              preference: preference)
    }

    static func applying(
        to candidates: [Candidate], dateEntries: [DicdataElement], readingCount: Int,
        preference: Config.DateFormatPreference.Value,
        now: Date = Date(), calendar: Calendar = .current
    ) -> [Candidate] {
        guard preference != .standard, !dateEntries.isEmpty else {
            return candidates
        }
        var entries = dateEntries
        if preference == .monthDay {
            for entry in dateEntries {
                guard let padded = paddedMonthDay(entry.word), padded != entry.word else { continue }
                entries.append(.init(word: padded, ruby: entry.ruby, cid: CIDData.固有名詞.cid,
                                     mid: MIDData.一般.mid, value: entry.value()))
            }
        }
        if preference == .weekday {
            for entry in dateEntries {
                guard let text = numericWeekday(entry, now: now, calendar: calendar) else { continue }
                entries.append(.init(word: text, ruby: entry.ruby, cid: CIDData.固有名詞.cid,
                                     mid: MIDData.一般.mid, value: entry.value()))
            }
        }
        let words = Set(entries.map(\.word))
        // 希望した書式がエンジンの候補数制限で落ちても、元の候補を残して補完する。
        var seen = Set(candidates.map(\.text))
        let missing = entries.filter { isPreferred($0.word, preference: preference) && seen.insert($0.word).inserted }
        let additions = missing.map { entry in
            Candidate(text: entry.word, value: entry.value(), composingCount: .surfaceCount(readingCount),
                      lastMid: MIDData.一般.mid, data: [entry], isLearningTarget: false)
        }
        var result = candidates
        result.insert(contentsOf: additions, at: min(5, result.count))
        return reordered(result, dateWords: words, preference: preference)
    }

    static func reordered(
        _ candidates: [Candidate], dateWords: Set<String>, preference: Config.DateFormatPreference.Value
    ) -> [Candidate] {
        guard preference != .standard else {
            return candidates
        }
        let indices = candidates.indices.filter { dateWords.contains(candidates[$0].text) }
        let dates = indices.map { candidates[$0] }
        let ordered = dates.filter { isPreferred($0.text, preference: preference) }
            + dates.filter { !isPreferred($0.text, preference: preference) }
        var result = candidates
        for (index, candidate) in zip(indices, ordered) { result[index] = candidate }
        return result
    }

    static func paddedMonthDay(_ text: String) -> String? {
        guard text.range(of: #"^[0-9]{1,2}/[0-9]{1,2}$"#, options: .regularExpression) != nil else {
            return nil
        }
        let parts = text.split(separator: "/").compactMap { Int($0) }
        guard parts.count == 2, (1...12).contains(parts[0]) else {
            return nil
        }
        let monthLengths = [31, 29, 31, 30, 31, 30, 31, 31, 30, 31, 30, 31]
        guard (1...monthLengths[parts[0] - 1]).contains(parts[1]) else {
            return nil
        }
        return String(format: "%02d/%02d", parts[0], parts[1])
    }

    /// 年のない4桁入力だけを今年の月日として解釈する。相対日付の年は変更しない。
    static func numericWeekday(_ entry: DicdataElement, now: Date, calendar: Calendar) -> String? {
        let digits = entry.ruby.unicodeScalars.compactMap { scalar -> Int? in
            switch scalar.value {
            case 0x30...0x39: Int(scalar.value - 0x30)
            case 0xFF10...0xFF19: Int(scalar.value - 0xFF10)
            default: nil
            }
        }
        guard entry.ruby.unicodeScalars.count == 4, digits.count == 4,
              paddedMonthDay(entry.word) == "\(digits[0])\(digits[1])/\(digits[2])\(digits[3])" else {
            return nil
        }
        var gregorian = Calendar(identifier: .gregorian)
        gregorian.timeZone = calendar.timeZone
        let year = gregorian.component(.year, from: now)
        let month = digits[0] * 10 + digits[1]
        let day = digits[2] * 10 + digits[3]
        guard let date = gregorian.date(from: DateComponents(year: year, month: month, day: day, hour: 12)),
              gregorian.component(.year, from: date) == year,
              gregorian.component(.month, from: date) == month,
              gregorian.component(.day, from: date) == day else {
            return nil
        }
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "ja_JP")
        formatter.calendar = gregorian
        formatter.timeZone = gregorian.timeZone
        formatter.dateFormat = "M月d日（E）"
        return formatter.string(from: date)
    }

    private static func isPreferred(_ text: String, preference: Config.DateFormatPreference.Value) -> Bool {
        switch preference {
        case .standard: false
        case .monthDay: paddedMonthDay(text) == text
        case .weekday:
            text.range(of: #"[（(][日月火水木金土][）)]"#, options: .regularExpression) != nil
        }
    }
}
