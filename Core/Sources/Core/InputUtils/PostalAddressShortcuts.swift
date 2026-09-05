import Foundation

enum PostalAddressShortcuts {
    // static let は初回参照時に一度だけ読み込み、以後は不変の辞書を共有する。
    private static let addressIndex: [String: [String]] = {
        guard let url = Bundle.module.url(forResource: "postal-addresses", withExtension: "tsv"),
              let contents = try? String(contentsOf: url, encoding: .utf8) else {
            return [:]
        }
        return parseAddresses(contents)
    }()

    static func addresses(matching reading: String) -> [String] {
        // 通常の文字入力ではリソースの読み込み・辞書構築を行わない。
        guard let postalCode = normalizedPostalCode(matching: reading) else {
            return []
        }
        return addressIndex[postalCode] ?? []
    }

    static func normalizedPostalCode(matching reading: String) -> String? {
        let scalars = Array(reading.unicodeScalars)
        guard scalars.count == 7 || scalars.count == 8 else {
            return nil
        }
        var digits = ""
        digits.reserveCapacity(7)
        for (index, scalar) in scalars.enumerated() {
            if scalars.count == 8, index == 3 {
                switch scalar.value {
                case 0x2D, 0xFF70, 0x30FC, 0xFF0D, 0x2212:
                    continue
                default:
                    return nil
                }
            }
            switch scalar.value {
            case 0x30...0x39:
                digits.unicodeScalars.append(scalar)
            case 0xFF10...0xFF19:
                digits.unicodeScalars.append(Unicode.Scalar(scalar.value - 0xFF10 + 0x30)!)
            default:
                return nil
            }
        }
        return digits
    }

    static func parseAddresses(_ contents: String) -> [String: [String]] {
        var addresses: [String: [String]] = [:]
        for line in contents.split(whereSeparator: \.isNewline) {
            let fields = line.split(separator: "\t", maxSplits: 1, omittingEmptySubsequences: false)
            guard fields.count == 2 else {
                continue
            }
            let postalCode = String(fields[0])
            guard postalCode.utf8.count == 7,
                  postalCode.utf8.allSatisfy({ (0x30...0x39).contains($0) }) else {
                continue
            }
            let address = fields[1].trimmingCharacters(in: .whitespaces)
            guard !address.isEmpty, !address.contains("\t") else {
                continue
            }
            if !(addresses[postalCode]?.contains(address) ?? false) {
                addresses[postalCode, default: []].append(address)
            }
        }
        return addresses
    }
}
