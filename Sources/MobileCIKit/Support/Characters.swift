/// ASCII character classes. Version numbers, build numbers and Flutter versions are ASCII;
/// `Character.isNumber` would also accept digits of other scripts (`٤`), which tools reject.
extension Character {
    var isASCIIDigit: Bool { asciiDigitValue != nil }

    var asciiDigitValue: Int? {
        guard let ascii = asciiValue, ascii >= 48, ascii <= 57 else { return nil }
        return Int(ascii - 48)
    }

    var isASCIILetterOrDigit: Bool {
        guard let ascii = asciiValue else { return false }
        return (48...57).contains(ascii) || (65...90).contains(ascii) || (97...122).contains(ascii)
    }
}
