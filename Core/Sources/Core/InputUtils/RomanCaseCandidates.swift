import Foundation

/// Case variants of the original keyboard input, before kana conversion.
enum RomanCaseCandidates {
    static func variants(for input: String) -> [String] {
        guard input.unicodeScalars.allSatisfy({ (0x21...0x7e).contains($0.value) }),
              input.unicodeScalars.contains(where: { (0x41...0x5a).contains($0.value) || (0x61...0x7a).contains($0.value) }) else {
            return []
        }
        let lower = input.lowercased()
        let title = lower.prefix(1).uppercased() + lower.dropFirst()
        var seen = Set<String>()
        return [lower, title, input.uppercased()].filter { seen.insert($0).inserted }
    }
}
