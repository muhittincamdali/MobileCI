/// How serious a finding is. The order is `note < warning < error`.
public enum Severity: String, Sendable, Codable, CaseIterable, Comparable {
    case note
    case warning
    case error

    private var rank: Int {
        switch self {
        case .note: return 0
        case .warning: return 1
        case .error: return 2
        }
    }

    public static func < (lhs: Severity, rhs: Severity) -> Bool {
        lhs.rank < rhs.rank
    }
}

/// One problem found in one file.
///
/// The message is written by MobileCI. When it names something from the file (an action
/// reference, an expression, a secret's name), that text was checked against a narrow pattern
/// first, so a finding never repeats arbitrary file content such as a secret's value.
public struct Finding: Sendable, Hashable, Codable {
    public let rule: RuleID
    public let severity: Severity
    public let path: String
    public let location: SourceLocation
    public let message: String

    public init(rule: RuleID, severity: Severity, path: String, location: SourceLocation, message: String) {
        self.rule = rule
        self.severity = severity
        self.path = path
        self.location = location
        self.message = message
    }

    /// Findings sorted by path, then position, then rule.
    static func sorted(_ findings: [Finding]) -> [Finding] {
        findings.sorted {
            ($0.path, $0.location, $0.rule.rawValue) < ($1.path, $1.location, $1.rule.rawValue)
        }
    }
}
