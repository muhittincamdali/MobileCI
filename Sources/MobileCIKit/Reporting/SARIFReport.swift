/// SARIF 2.1.0, the format GitHub code scanning reads.
enum SARIFReport {
    private struct Log: Encodable {
        let version = "2.1.0"
        let schema = "https://json.schemastore.org/sarif-2.1.0.json"
        let runs: [Run]

        enum CodingKeys: String, CodingKey {
            case version
            case schema = "$schema"
            case runs
        }
    }

    private struct Run: Encodable {
        let tool: Tool
        let results: [Result]
    }

    private struct Tool: Encodable {
        let driver: Driver
    }

    private struct Driver: Encodable {
        let name = "MobileCI"
        let version = MobileCIInfo.version
        let informationUri = MobileCIInfo.repositoryURL
        let rules: [Rule]
    }

    private struct Rule: Encodable {
        let id: String
        let name: String
        let shortDescription: Text
        let help: Text
        let helpUri: String
        let defaultConfiguration: Configuration
    }

    private struct Configuration: Encodable {
        let level: String
    }

    private struct Text: Encodable {
        let text: String
    }

    private struct Result: Encodable {
        let ruleId: String
        let ruleIndex: Int
        let level: String
        let message: Text
        let locations: [Location]
    }

    private struct Location: Encodable {
        let physicalLocation: PhysicalLocation
    }

    private struct PhysicalLocation: Encodable {
        let artifactLocation: ArtifactLocation
        let region: Region
    }

    private struct ArtifactLocation: Encodable {
        let uri: String
    }

    private struct Region: Encodable {
        let startLine: Int
        let startColumn: Int
    }

    static func render(_ findings: [Finding]) -> String {
        let rules = RuleID.allCases
        let log = Log(runs: [
            Run(
                tool: Tool(driver: Driver(rules: rules.map { rule in
                    Rule(id: rule.rawValue, name: rule.name, shortDescription: Text(text: rule.summary),
                         help: Text(text: rule.fix), helpUri: MobileCIInfo.rulesURL,
                         defaultConfiguration: Configuration(level: level(rule.defaultSeverity)))
                })),
                results: findings.map { finding in
                    Result(
                        ruleId: finding.rule.rawValue,
                        ruleIndex: rules.firstIndex(of: finding.rule) ?? 0,
                        level: level(finding.severity),
                        message: Text(text: finding.message),
                        locations: [Location(physicalLocation: PhysicalLocation(
                            artifactLocation: ArtifactLocation(uri: uri(for: finding.path)),
                            region: Region(startLine: finding.location.line, startColumn: finding.location.column)
                        ))]
                    )
                }
            )
        ])
        return JSONReport.encode(log)
    }

    private static func level(_ severity: Severity) -> String {
        switch severity {
        case .error: return "error"
        case .warning: return "warning"
        case .note: return "note"
        }
    }

    /// A relative URI reference: path separators kept, everything else outside the unreserved
    /// set percent-encoded (RFC 3986).
    static func uri(for path: String) -> String {
        var result = ""
        for byte in path.utf8 {
            switch byte {
            case UInt8(ascii: "a")...UInt8(ascii: "z"), UInt8(ascii: "A")...UInt8(ascii: "Z"),
                 UInt8(ascii: "0")...UInt8(ascii: "9"), UInt8(ascii: "-"), UInt8(ascii: "."),
                 UInt8(ascii: "_"), UInt8(ascii: "~"), UInt8(ascii: "/"):
                result.append(Character(Unicode.Scalar(byte)))
            default:
                result += "%" + String(byte, radix: 16, uppercase: true).leftPadded(to: 2)
            }
        }
        return result
    }
}

private extension String {
    func leftPadded(to width: Int) -> String {
        count >= width ? self : String(repeating: "0", count: width - count) + self
    }
}
