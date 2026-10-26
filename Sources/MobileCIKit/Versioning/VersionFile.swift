import Foundation

/// The kinds of files that hold an app's version.
public enum VersionFileFormat: String, Sendable, Equatable {
    /// `version: 1.2.3+45` in a Flutter `pubspec.yaml`.
    case pubspec = "pubspec.yaml"
    /// The top-level `version` of `package.json`.
    case packageJSON = "package.json"
    /// `expo.version`, `expo.ios.buildNumber` and `expo.android.versionCode` in `app.json`.
    case expo = "app.json"
    /// Every `MARKETING_VERSION` and `CURRENT_PROJECT_VERSION` in an Xcode `project.pbxproj`.
    case xcodeProject = "project.pbxproj"
    /// Literal `versionName` and `versionCode` values in an Android `build.gradle(.kts)`.
    case gradle = "build.gradle"
}

/// One file with version fields, read so they can be rewritten in place: the rest of the file
/// keeps its bytes.
public struct VersionFile: Sendable, Equatable {
    public let path: String
    public let format: VersionFileFormat
    let url: URL
    let text: String
    let fields: [Field]

    struct Field: Sendable, Equatable {
        enum Role: Sendable, Equatable { case version, build }
        let role: Role
        let range: Range<String.Index>
        let value: String
        /// Written before the new value when the field does not exist yet (`+` for a
        /// Flutter build number after `version: 1.2.3`).
        let insertionPrefix: String?
    }

    /// The version values in the file, one per field.
    public var versions: [String] { fields.filter { $0.role == .version && $0.insertionPrefix == nil }.map(\.value) }
    /// The build numbers in the file, one per field.
    public var buildNumbers: [String] { fields.filter { $0.role == .build && $0.insertionPrefix == nil }.map(\.value) }

    /// The text with every version field set to `version` and every build field to `build`
    /// (`nil` leaves that kind unchanged).
    func updatedText(version: String?, build: String?) -> String {
        var result = text
        for field in fields.sorted(by: { $0.range.lowerBound > $1.range.lowerBound }) {
            let replacement: String?
            switch field.role {
            case .version: replacement = version
            case .build: replacement = build.map { (field.insertionPrefix ?? "") + $0 }
            }
            if let replacement { result.replaceSubrange(field.range, with: replacement) }
        }
        return result
    }

    init?(url: URL, path: String, format: VersionFileFormat) {
        let limit = format == .xcodeProject ? TextFile.projectFileLimit : TextFile.defaultLimit
        guard let text = try? TextFile.read(url, limit: limit) else { return nil }
        let fields: [Field]
        switch format {
        case .pubspec: fields = VersionFieldReader.pubspec(text)
        case .packageJSON: fields = VersionFieldReader.json(text, [(["version"], .version)])
        case .expo: fields = VersionFieldReader.json(text, [(["expo", "version"], .version),
                                                            (["expo", "ios", "buildNumber"], .build),
                                                            (["expo", "android", "versionCode"], .build)])
        case .xcodeProject: fields = VersionFieldReader.buildSettings(text)
        case .gradle: fields = VersionFieldReader.gradle(text)
        }
        guard !fields.isEmpty else { return nil }
        self.url = url
        self.path = path
        self.format = format
        self.text = text
        self.fields = fields
    }
}

/// Finds version fields in the text of each format.
enum VersionFieldReader {
    typealias Field = VersionFile.Field

    static func pubspec(_ text: String) -> [Field] {
        guard let line = lines(of: text).first(where: { text[$0].hasPrefix("version:") }) else { return [] }
        guard let token = valueToken(in: text, after: text.index(line.lowerBound, offsetBy: "version:".count), lineEnd: line.upperBound) else {
            return []
        }
        let value = text[token]
        if let plus = value.firstIndex(of: "+") {
            return [Field(role: .version, range: token.lowerBound..<plus, value: String(text[token.lowerBound..<plus]), insertionPrefix: nil),
                    Field(role: .build, range: text.index(after: plus)..<token.upperBound,
                          value: String(text[text.index(after: plus)..<token.upperBound]), insertionPrefix: nil)]
        }
        return [Field(role: .version, range: token, value: String(value), insertionPrefix: nil),
                Field(role: .build, range: token.upperBound..<token.upperBound, value: "", insertionPrefix: "+")]
    }

    static func json(_ text: String, _ paths: [([String], Field.Role)]) -> [Field] {
        guard (try? JSONSerialization.jsonObject(with: Data(text.utf8))) is [String: Any] else { return [] }
        return paths.compactMap { path, role in
            guard let match = JSONValueLocator.find(path, in: text) else { return nil }
            return Field(role: role, range: match.range, value: String(text[match.range]), insertionPrefix: nil)
        }
    }

    /// `MARKETING_VERSION = 1.2;` and `CURRENT_PROJECT_VERSION = 7;` lines; a value that is
    /// a build setting reference such as `$(inherited)` is left alone.
    static func buildSettings(_ text: String) -> [Field] {
        lines(of: text).compactMap { line in
            let content = text[line]
            let trimmed = content.drop { $0 == " " || $0 == "\t" }
            let role: Field.Role
            let key: String
            if trimmed.hasPrefix("MARKETING_VERSION = ") {
                (role, key) = (.version, "MARKETING_VERSION = ")
            } else if trimmed.hasPrefix("CURRENT_PROJECT_VERSION = ") {
                (role, key) = (.build, "CURRENT_PROJECT_VERSION = ")
            } else {
                return nil
            }
            var start = text.index(trimmed.startIndex, offsetBy: key.count)
            guard var end = content.lastIndex(of: ";"), start < end else { return nil }
            if text[start] == "\"", text.index(after: start) < end, text[text.index(before: end)] == "\"" {
                start = text.index(after: start)
                end = text.index(before: end)
            }
            guard start < end else { return nil }
            let value = String(text[start..<end])
            guard value.allSatisfy({ $0.isASCIIDigit || $0 == "." || $0 == "-" || $0.isASCIILetterOrDigit }),
                  !value.contains("$") else { return nil }
            return Field(role: role, range: start..<end, value: value, insertionPrefix: nil)
        }
    }

    /// `versionCode 7`, `versionCode = 7`, `versionName "1.2"`, `versionName = "1.2"`.
    static func gradle(_ text: String) -> [Field] {
        lines(of: text).compactMap { line in
            let content = text[line]
            let trimmed = content.drop { $0 == " " || $0 == "\t" }
            for (key, role) in [("versionCode", Field.Role.build), ("versionName", .version)] where trimmed.hasPrefix(key) {
                var rest = trimmed.dropFirst(key.count)
                guard rest.first == " " || rest.first == "=" || rest.first == "\t" else { return nil }
                rest = rest.drop { $0 == " " || $0 == "=" || $0 == "\t" }
                if role == .version {
                    guard rest.first == "\"", let close = rest.dropFirst().firstIndex(of: "\"") else { return nil }
                    let range = rest.index(after: rest.startIndex)..<close
                    return Field(role: role, range: range, value: String(text[range]), insertionPrefix: nil)
                }
                let digits = rest.prefix { $0.isASCIIDigit }
                guard !digits.isEmpty, digits.endIndex == rest.endIndex || rest[digits.endIndex].isWhitespace else { return nil }
                return Field(role: role, range: digits.startIndex..<digits.endIndex, value: String(digits), insertionPrefix: nil)
            }
            return nil
        }
    }

    /// Line ranges without their line breaks.
    static func lines(of text: String) -> [Range<String.Index>] {
        var result: [Range<String.Index>] = []
        var start = text.startIndex
        while start < text.endIndex {
            let end = text[start...].firstIndex(where: { $0 == "\n" || $0 == "\r\n" }) ?? text.endIndex
            result.append(start..<end)
            start = end < text.endIndex ? text.index(after: end) : end
        }
        return result
    }

    /// The value after `key:` on a YAML line, without quotes and without a trailing comment.
    private static func valueToken(in text: String, after start: String.Index, lineEnd: String.Index) -> Range<String.Index>? {
        var lower = start
        while lower < lineEnd, text[lower] == " " || text[lower] == "\t" { lower = text.index(after: lower) }
        guard lower < lineEnd else { return nil }
        if text[lower] == "\"" || text[lower] == "'" {
            let quote = text[lower]
            let contentStart = text.index(after: lower)
            guard let close = text[contentStart..<lineEnd].firstIndex(of: quote) else { return nil }
            return contentStart..<close
        }
        var upper = lower
        while upper < lineEnd, !(text[upper] == " " || text[upper] == "\t" || text[upper] == "#") { upper = text.index(after: upper) }
        return lower..<upper
    }
}
