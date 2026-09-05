@testable import Core
import Testing

@Suite("Hyphenated code candidates")
struct HyphenatedCodeCandidatesTests {
    @Test func requestedPostalCodeHasBothSeparatorCandidates() {
        #expect(HyphenatedCodeCandidates.variants(for: "457ー0067") == ["457ｰ0067", "457-0067"])
    }

    @Test(arguments: ["-", "ｰ", "ー", "－", "−"])
    func supportsEachSeparator(_ separator: String) {
        let reading = "457" + separator + "0067"
        let expected = ["457ｰ0067", "457-0067"].filter { $0 != reading }
        #expect(HyphenatedCodeCandidates.variants(for: reading) == expected)
    }

    @Test func preservesAlphanumericWidthAndCase() {
        #expect(HyphenatedCodeCandidates.variants(for: "Ａb１２ーCd３4") == ["Ａb１２ｰCd３4", "Ａb１２-Cd３4"])
        #expect(HyphenatedCodeCandidates.variants(for: "ａｚ－ＡＺ") == ["ａｚｰＡＺ", "ａｚ-ＡＺ"])
    }

    @Test func normalizesAllSeparatorsForPhoneNumbersAndIdentifiers() {
        #expect(HyphenatedCodeCandidates.variants(for: "090ー1234－5678") == ["090ｰ1234ｰ5678", "090-1234-5678"])
        #expect(HyphenatedCodeCandidates.variants(for: "ID-ABｰ12−34") == ["IDｰABｰ12ｰ34", "ID-AB-12-34"])
    }

    @Test func omitsTheUnchangedVariant() {
        #expect(HyphenatedCodeCandidates.variants(for: "457ｰ0067") == ["457-0067"])
        #expect(HyphenatedCodeCandidates.variants(for: "457-0067") == ["457ｰ0067"])
    }

    @Test func permitsLeadingTrailingAndConsecutiveSeparators() {
        #expect(HyphenatedCodeCandidates.variants(for: "ーAーー") == ["ｰAｰｰ", "-A--"])
        #expect(HyphenatedCodeCandidates.variants(for: "−1") == ["ｰ1", "-1"])
    }

    @Test(arguments: [
        "", "ー", "ｰ", "-", "－", "−", "ーー", "-ｰー－−", "4570067", "ABC", "１２３",
        "コーヒー", "こーひー", "東京都ー1", "〒457ー0067", "番号457ー0067", "457ー0067です",
        "457ー0067 ", " 457ー0067", "457ー0067\n", "A_Bー1", "A.1ー2", "A/1ー2", "Aー🙂",
        "٤٥٧ー0067", "④⑤⑦ー0067", "A–1", "A—1", "éー1"
    ])
    func rejectsNonCodeOrSeparatorOnlyReadings(_ reading: String) {
        #expect(HyphenatedCodeCandidates.variants(for: reading).isEmpty)
    }
}
