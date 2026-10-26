/// The part of a version that a bump increments.
public enum VersionPart: String, Sendable, CaseIterable {
    case major
    case minor
    case patch
}

/// Why a version could not be read or changed.
public enum VersionError: Error, Equatable, Sendable, CustomStringConvertible {
    case invalidVersion(String)
    case invalidBuildNumber(String)
    case tooLarge(String, limit: Int)
    case nothingToChange(String)

    public var description: String {
        switch self {
        case .invalidVersion(let text):
            return "\(text.sanitizedForTerminal.truncated(to: 60)) is not a version: use 1 to 3 numbers separated by dots, such as 2.4.1."
        case .invalidBuildNumber(let text):
            return "\(text.sanitizedForTerminal.truncated(to: 60)) is not a build number: use digits only, such as 42."
        case .tooLarge(let text, let limit):
            return "\(text.sanitizedForTerminal.truncated(to: 60)) is larger than \(limit), the largest value Google Play accepts as a version code."
        case .nothingToChange(let reason):
            return reason
        }
    }
}

/// A user-facing version: `CFBundleShortVersionString`, `versionName`, the part of a Flutter
/// version before `+`. One to three numbers, with an optional `-prerelease` suffix (semver).
public struct MarketingVersion: Sendable, Equatable, Comparable, CustomStringConvertible {
    public let components: [Int]
    public let prerelease: String?

    /// The largest number one component may have; larger values are refused instead of being
    /// read into an `Int` that a bump could overflow.
    public static let maximumComponent = 999_999_999

    public init(_ text: String) throws(VersionError) {
        let trimmed = text.trimmingCharactersInSet(" \t")
        let main: Substring
        let prerelease: String?
        if let dash = trimmed.firstIndex(of: "-") {
            main = trimmed[..<dash]
            let suffix = trimmed[trimmed.index(after: dash)...]
            guard !suffix.isEmpty, suffix.count <= 64, suffix.allSatisfy({ $0.isASCIILetterOrDigit || $0 == "." || $0 == "-" }) else {
                throw .invalidVersion(text)
            }
            prerelease = String(suffix)
        } else {
            main = Substring(trimmed)
            prerelease = nil
        }
        let parts = main.split(separator: ".", omittingEmptySubsequences: false)
        guard (1...3).contains(parts.count) else { throw .invalidVersion(text) }
        var components: [Int] = []
        for part in parts {
            guard let value = DecimalNumber.parse(part, maximum: Self.maximumComponent) else { throw .invalidVersion(text) }
            components.append(value)
        }
        self.components = components
        self.prerelease = prerelease
    }

    private init(components: [Int]) {
        self.components = components
        self.prerelease = nil
    }

    /// The next version: `2.4.1` → major `3.0.0`, minor `2.5.0`, patch `2.4.2`. A shorter
    /// version grows to the bumped part (`1.2` → patch `1.2.1`); a prerelease suffix is dropped.
    public func bumped(_ part: VersionPart) throws(VersionError) -> MarketingVersion {
        let index: Int
        switch part {
        case .major: index = 0
        case .minor: index = 1
        case .patch: index = 2
        }
        var next = components
        while next.count <= index { next.append(0) }
        guard next[index] < Self.maximumComponent else {
            throw .tooLarge(description, limit: Self.maximumComponent)
        }
        next[index] += 1
        for later in next.indices where later > index { next[later] = 0 }
        return MarketingVersion(components: next)
    }

    public var description: String {
        components.map(String.init).joined(separator: ".") + (prerelease.map { "-" + $0 } ?? "")
    }

    /// Compares the numbers; a missing component counts as 0 and a prerelease sorts before
    /// the release.
    public static func < (lhs: MarketingVersion, rhs: MarketingVersion) -> Bool {
        let count = max(lhs.components.count, rhs.components.count)
        for index in 0..<count {
            let left = index < lhs.components.count ? lhs.components[index] : 0
            let right = index < rhs.components.count ? rhs.components[index] : 0
            if left != right { return left < right }
        }
        return lhs.prerelease != nil && rhs.prerelease == nil
    }
}

/// A build number: digits only. The limit is Google Play's for `versionCode`, which a Flutter
/// build number and Expo's `android.versionCode` become.
public struct BuildNumber: Sendable, Equatable, Comparable, CustomStringConvertible {
    public let value: Int

    public static let maximum = 2_100_000_000

    public init(_ text: String) throws(VersionError) {
        let trimmed = text.trimmingCharactersInSet(" \t\"")
        guard trimmed.allSatisfy(\.isASCIIDigit), !trimmed.isEmpty else { throw .invalidBuildNumber(text) }
        guard let value = DecimalNumber.parse(Substring(trimmed), maximum: Self.maximum) else {
            throw .tooLarge(trimmed, limit: Self.maximum)
        }
        self.value = value
    }

    public init(value: Int) throws(VersionError) {
        guard (0...Self.maximum).contains(value) else { throw .tooLarge(String(value), limit: Self.maximum) }
        self.value = value
    }

    public func incremented() throws(VersionError) -> BuildNumber {
        guard value < Self.maximum else { throw .tooLarge(String(value + 1), limit: Self.maximum) }
        return try BuildNumber(value: value + 1)
    }

    public var description: String { String(value) }

    public static func < (lhs: BuildNumber, rhs: BuildNumber) -> Bool { lhs.value < rhs.value }
}

/// Reads non-negative decimal numbers without `Int(_:)`'s acceptance of `+` signs and without
/// ever forming a value above `maximum`, so no conversion can trap or wrap.
enum DecimalNumber {
    static func parse(_ text: Substring, maximum: Int) -> Int? {
        guard !text.isEmpty, text.count <= 18 else { return nil }
        var value = 0
        for character in text {
            guard let digit = character.asciiDigitValue else { return nil }
            value = value * 10 + digit
            guard value <= maximum else { return nil }
        }
        return value
    }
}

extension StringProtocol {
    func trimmingCharactersInSet(_ characters: String) -> String {
        var slice = Substring(self)
        while let first = slice.first, characters.contains(first) { slice.removeFirst() }
        while let last = slice.last, characters.contains(last) { slice.removeLast() }
        return String(slice)
    }
}
