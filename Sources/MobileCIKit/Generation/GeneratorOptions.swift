import Foundation

/// Values a generated workflow uses. The defaults match GitHub's runner images in October 2026:
/// `macos-26` (arm64, Xcode 26.6 default, iOS 26.5 simulators with iPhone 17) and
/// `ubuntu-24.04`.
public struct GeneratorOptions: Sendable, Equatable {
    /// The branch whose pushes run the workflow.
    public var branch: String = "main"
    public var macOSRunner: String = "macos-26"
    public var linuxRunner: String = "ubuntu-24.04"
    /// Selected through `DEVELOPER_DIR=/Applications/Xcode_<version>.app/Contents/Developer`.
    public var xcodeVersion: String = "26.6"
    /// The simulator for `xcodebuild test`, by device name.
    public var simulator: String = "iPhone 17"
    /// Used when the project has no `.nvmrc` or `.node-version`.
    public var nodeVersion: String = "24"
    /// The JDK for Android builds; Android Gradle Plugin 8 and later need 17 or newer.
    public var javaVersion: String = "17"
    /// Used when `pubspec.yaml` has no exact `environment: flutter:` and there is no `.fvmrc`.
    public var flutterVersion: String = "3.47.8"
    /// Builds this scheme instead of ``XcodeProject/defaultScheme``.
    public var scheme: String?

    public init() {}

    /// Checks every value that is written into a workflow. Values end up inside YAML and shell
    /// scripts, so quotes, `$`, backslashes, braces, control characters and `${{` are refused
    /// rather than escaped: a scheme or branch with such a name would not work on CI anyway.
    public func validated() throws(GeneratorError) -> GeneratorOptions {
        try Validation.check("branch", branch, allowed: Validation.reference)
        try Validation.check("macOS runner", macOSRunner, allowed: Validation.label)
        try Validation.check("Linux runner", linuxRunner, allowed: Validation.label)
        try Validation.check("Xcode version", xcodeVersion, allowed: Validation.label)
        try Validation.check("simulator", simulator, allowed: Validation.name)
        try Validation.check("Node version", nodeVersion, allowed: Validation.reference.union(["*"]))
        try Validation.check("Java version", javaVersion, allowed: Validation.label)
        try Validation.check("Flutter version", flutterVersion, allowed: Validation.label)
        if let scheme { try Validation.check("scheme", scheme, allowed: Validation.name) }
        return self
    }
}

/// Why no workflow could be written.
public enum GeneratorError: Error, Equatable, Sendable, CustomStringConvertible {
    case invalidValue(field: String, reason: String)
    case noScheme(project: String)
    case unknownScheme(String, available: [String])
    case unsupported(String)

    public var description: String {
        switch self {
        case .invalidValue(let field, let reason):
            return "The \(field) cannot be used in a workflow: \(reason)."
        case .noScheme(let project):
            return "\(project.sanitizedForTerminal) has no shared scheme. In Xcode choose Product › Scheme › Manage Schemes…, tick Shared, commit the .xcscheme file and run init again."
        case .unknownScheme(let name, let available):
            let list = available.map(\.sanitizedForTerminal).joined(separator: ", ")
            return "No shared scheme named \(name.sanitizedForTerminal); shared schemes: \(list.isEmpty ? "none" : list)."
        case .unsupported(let reason):
            return reason
        }
    }
}

enum Validation {
    static let label = CharacterSet(charactersIn:
        "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789._-")
    static let reference = label.union(["/"])
    /// Scheme, project and simulator names: letters and digits of any script, spaces and a
    /// few punctuation marks Xcode names commonly use.
    static let name = CharacterSet.letters.union(.decimalDigits).union(CharacterSet(charactersIn: " ._-+()&,@"))
    static let path = name.union(["/"])

    static func check(_ field: String, _ value: String, allowed: CharacterSet) throws(GeneratorError) {
        guard !value.isEmpty else { throw .invalidValue(field: field, reason: "it is empty") }
        guard value.count <= 200 else { throw .invalidValue(field: field, reason: "it is longer than 200 characters") }
        guard value.unicodeScalars.allSatisfy(allowed.contains) else {
            throw .invalidValue(field: field, reason: "it contains characters other than letters, digits and \(describe(allowed))")
        }
        guard value.trimmingCharacters(in: .whitespaces) == value else {
            throw .invalidValue(field: field, reason: "it starts or ends with a space")
        }
    }

    /// A relative folder inside the repository: no leading `/`, no `.` or `..` segment.
    static func checkFolder(_ field: String, _ value: String) throws(GeneratorError) {
        guard value != "." else { return }
        try check(field, value, allowed: path)
        let segments = value.split(separator: "/", omittingEmptySubsequences: false)
        guard !value.hasPrefix("/"), segments.allSatisfy({ !$0.isEmpty && $0 != "." && $0 != ".." }) else {
            throw .invalidValue(field: field, reason: "it must be a relative folder without `.` or `..` segments")
        }
    }

    private static func describe(_ allowed: CharacterSet) -> String {
        if allowed == label { return "`. _ -`" }
        if allowed == reference || allowed == reference.union(["*"]) { return "`. _ - /`" }
        return "spaces and `. _ - + ( ) & , @`"
    }
}
