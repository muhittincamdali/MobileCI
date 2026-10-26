import ArgumentParser
import Foundation
import MobileCIKit

extension ReportFormat: ExpressibleByArgument {}

/// The lowest severity that makes `lint` exit with status 1.
enum FailLevel: String, ExpressibleByArgument, CaseIterable {
    case error
    case warning
    case note
    case never

    var threshold: Severity? {
        switch self {
        case .error: return .error
        case .warning: return .warning
        case .note: return .note
        case .never: return nil
        }
    }
}

struct LintCommand: ParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "lint",
        abstract: "Check GitHub Actions workflows for mobile CI problems.",
        discussion: """
        With no path, checks .github/workflows in the current folder. A folder argument means \
        its .github/workflows (or its .yml files when it has none). Exit status: 0 when no \
        finding reaches --fail-on, 1 when one does.
        Silence a rule on one line with `# mobileci-ignore MCI012`, in a file with \
        `# mobileci-ignore-file MCI012`. Rules: `mobileci rules`.
        """
    )

    @Argument(help: "Workflow files or folders.")
    var paths: [String] = []

    @Option(help: "Output format: text, json, github (annotations) or sarif.")
    var format: ReportFormat = .text

    @Option(help: "Rules to skip, by identifier or name, separated by commas.")
    var disable: String?

    @Option(name: .customLong("fail-on"), help: "Exit with status 1 for findings of this severity or higher: error, warning, note or never.")
    var failOn: FailLevel = .warning

    func validate() throws {
        _ = try disabledRules()
    }

    func run() throws {
        let targets = paths.isEmpty ? [CommandLinePath.currentDirectory] : paths.map(CommandLinePath.url)
        let files = WorkflowLinter.workflowFiles(for: targets)
        guard !files.isEmpty else {
            StandardError.write("No workflow files found (looked for .github/workflows/*.yml).")
            throw ExitCode(1)
        }
        let linter = WorkflowLinter(disabledRules: try disabledRules())
        let findings = files.flatMap { linter.lint(fileAt: $0, displayPath: CommandLinePath.display($0)) }
        print(format.render(findings, filesChecked: files.count), terminator: "")
        if let threshold = failOn.threshold, findings.contains(where: { $0.severity >= threshold }) {
            throw ExitCode(1)
        }
    }

    private func disabledRules() throws -> Set<RuleID> {
        guard let disable else { return [] }
        var rules = Set<RuleID>()
        for name in disable.split(separator: ",") {
            guard let rule = RuleID(identifier: String(name)) else {
                throw ValidationError("Unknown rule \(String(name).sanitizedForTerminal); `mobileci rules` lists them.")
            }
            rules.insert(rule)
        }
        return rules
    }
}

struct RulesCommand: ParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "rules",
        abstract: "List the lint rules with what each one finds and how to fix it."
    )

    func run() {
        for rule in RuleID.allCases {
            print("\(rule.rawValue) \(rule.name) (\(rule.defaultSeverity.rawValue))")
            print("  \(rule.summary)")
            print("  Fix: \(rule.fix)")
        }
        print("\nDetails: \(MobileCIInfo.rulesURL)")
    }
}
