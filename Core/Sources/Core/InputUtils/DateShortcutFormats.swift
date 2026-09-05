import KanaKanjiConverterModuleWithDefaultDictionary

/// 日付ショートカットで共通の表記と候補スコア。
enum DateShortcutFormats {
    struct Format {
        let pattern: String
        let value: PValue
        let calendar: DateTemplateLiteral.CalendarType
    }

    static let all: [Format] = [
        .init(pattern: "M/d", value: -18, calendar: .western),
        .init(pattern: "yyyy/MM/dd", value: -18.1, calendar: .western),
        .init(pattern: "yyyy-MM-dd", value: -18.2, calendar: .western),
        .init(pattern: "M月d日（E）", value: -18.3, calendar: .western),
        .init(pattern: "yyyy年M月d日", value: -18.4, calendar: .western),
        .init(pattern: "Gyyyy年M月d日", value: -18.5, calendar: .japanese),
        .init(pattern: "E曜日", value: -18.6, calendar: .western)
    ]
}
