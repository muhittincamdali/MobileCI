import Foundation

/// The output formats of `mobileci lint`.
public enum ReportFormat: String, Sendable, CaseIterable {
    /// `path:line:column: severity[MCI001] message`, one finding per line, then a summary.
    case text
    /// A JSON object with `findings` and `summary`.
    case json
    /// GitHub Actions workflow commands (`::warning file=…::…`), shown as annotations on the
    /// pull request.
    case github
    /// SARIF 2.1.0 for GitHub code scanning (`github/codeql-action/upload-sarif`).
    case sarif

    public func render(_ findings: [Finding], filesChecked: Int) -> String {
        switch self {
        case .text: return TextReport.render(findings, filesChecked: filesChecked)
        case .json: return JSONReport.render(findings, filesChecked: filesChecked)
        case .github: return GitHubReport.render(findings)
        case .sarif: return SARIFReport.render(findings)
        }
    }
}

enum TextReport {
    static func render(_ findings: [Finding], filesChecked: Int) -> String {
        var lines = findings.map { finding in
            "\(finding.path.sanitizedForTerminal):\(finding.location.line):\(finding.location.column): "
                + "\(finding.severity.rawValue)[\(finding.rule.rawValue)] \(finding.message.sanitizedForTerminal)"
        }
        let errors = findings.filter { $0.severity == .error }.count
        let warnings = findings.filter { $0.severity == .warning }.count
        let notes = findings.filter { $0.severity == .note }.count
        let files = filesChecked == 1 ? "1 file" : "\(filesChecked) files"
        lines.append("\(files) checked: \(errors) error(s), \(warnings) warning(s), \(notes) note(s).")
        return lines.joined(separator: "\n") + "\n"
    }
}

enum JSONReport {
    private struct Document: Encodable {
        let tool: String
        let version: String
        let findings: [Entry]
        let summary: Summary
    }

    private struct Entry: Encodable {
        let rule: String
        let name: String
        let severity: String
        let path: String
        let line: Int
        let column: Int
        let message: String
    }

    private struct Summary: Encodable {
        let files: Int
        let errors: Int
        let warnings: Int
        let notes: Int
    }

    static func render(_ findings: [Finding], filesChecked: Int) -> String {
        let document = Document(
            tool: "mobileci",
            version: MobileCIInfo.version,
            findings: findings.map {
                Entry(rule: $0.rule.rawValue, name: $0.rule.name, severity: $0.severity.rawValue, path: $0.path,
                      line: $0.location.line, column: $0.location.column, message: $0.message)
            },
            summary: Summary(
                files: filesChecked,
                errors: findings.filter { $0.severity == .error }.count,
                warnings: findings.filter { $0.severity == .warning }.count,
                notes: findings.filter { $0.severity == .note }.count
            )
        )
        return encode(document)
    }

    static func encode<Value: Encodable>(_ value: Value) -> String {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys, .withoutEscapingSlashes]
        guard let data = try? encoder.encode(value), let text = String(data: data, encoding: .utf8) else {
            preconditionFailure("Encoding a report of strings and integers cannot fail.")
        }
        return text + "\n"
    }
}

/// Workflow commands. Values are escaped the way `@actions/core` escapes them, so text from a
/// file name or message cannot end the command early or start a second one.
enum GitHubReport {
    static func render(_ findings: [Finding]) -> String {
        findings.map { finding in
            let command: String
            switch finding.severity {
            case .error: command = "error"
            case .warning: command = "warning"
            case .note: command = "notice"
            }
            let properties = [
                "file=\(escapeProperty(finding.path))",
                "line=\(finding.location.line)",
                "col=\(finding.location.column)",
                "title=\(escapeProperty("\(finding.rule.rawValue) \(finding.rule.name)"))"
            ].joined(separator: ",")
            return "::\(command) \(properties)::\(escapeData(finding.message))\n"
        }.joined()
    }

    static func escapeData(_ text: String) -> String {
        text.replacingOccurrences(of: "%", with: "%25")
            .replacingOccurrences(of: "\r", with: "%0D")
            .replacingOccurrences(of: "\n", with: "%0A")
    }

    static func escapeProperty(_ text: String) -> String {
        escapeData(text)
            .replacingOccurrences(of: ":", with: "%3A")
            .replacingOccurrences(of: ",", with: "%2C")
    }
}
