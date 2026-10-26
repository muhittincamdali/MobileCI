import Foundation

/// Checks GitHub Actions workflow files against the rules in ``RuleID``.
///
/// ```swift
/// let linter = WorkflowLinter(disabledRules: [.checkoutPersistsCredentials])
/// let findings = linter.lint(text: yaml, path: ".github/workflows/ios.yml")
/// ```
///
/// The linter never runs anything from the workflow and never prints its content: findings
/// carry positions and messages written by MobileCI (see ``Finding``).
public struct WorkflowLinter: Sendable {
    public let disabledRules: Set<RuleID>

    public init(disabledRules: Set<RuleID> = []) {
        self.disabledRules = disabledRules
    }

    /// Lints one workflow given as text. `path` is only used in the findings.
    public func lint(text: String, path: String) -> [Finding] {
        let findings: [Finding]
        switch YAMLLoader.load(text) {
        case .failure(let error):
            findings = [invalid(path, Self.describe(error), at: Self.location(of: error))]
        case .success(let root):
            if let workflow = Workflow(root: root) {
                var context = RuleContext(path: path, workflow: workflow)
                Rules.checkAll(&context)
                findings = context.findings
            } else {
                findings = [invalid(path, "The file has no `jobs:` mapping, so it is not a workflow.", at: .start)]
            }
        }
        let suppressions = Suppressions(text: text)
        return Finding.sorted(findings.filter { !disabledRules.contains($0.rule) && !suppressions.isSuppressed($0) })
    }

    /// Lints one file. A file that cannot be read gives one ``RuleID/invalidWorkflow`` finding.
    public func lint(fileAt url: URL, displayPath: String) -> [Finding] {
        do {
            let text = try TextFile.read(url)
            return lint(text: text, path: displayPath)
        } catch {
            let reason: String
            switch error {
            case .tooLarge(_, let limit): reason = "The file is larger than \(limit / 1024) KiB and was not read."
            case .notUTF8: reason = "The file is not UTF-8 text."
            case .missing: reason = "The file does not exist."
            case .unreadable: reason = "The file cannot be read."
            }
            guard !disabledRules.contains(.invalidWorkflow) else { return [] }
            return [invalid(displayPath, reason, at: .start)]
        }
    }

    /// Entries read from one folder; `.github/workflows` holds a few dozen at most.
    public static let maximumFilesPerFolder = 10_000

    /// The workflow files to lint for the given paths: a file as given; a directory's
    /// `.github/workflows` folder when it has one, otherwise the `.yml` and `.yaml` files
    /// directly in it. Sorted, without duplicates.
    public static func workflowFiles(for paths: [URL]) -> [URL] {
        var files: [URL] = []
        let manager = FileManager.default
        for path in paths {
            var isDirectory: ObjCBool = false
            guard manager.fileExists(atPath: path.path, isDirectory: &isDirectory), isDirectory.boolValue else {
                files.append(path)
                continue
            }
            let workflows = path.appendingPathComponent(".github/workflows", isDirectory: true)
            let folder = manager.fileExists(atPath: workflows.path) ? workflows : path
            let entries = DirectoryListing.entries(of: folder, limit: maximumFilesPerFolder).urls
            files += entries.filter { ["yml", "yaml"].contains($0.pathExtension.lowercased()) }
        }
        var seen = Set<String>()
        return files.filter { seen.insert($0.standardizedFileURL.path).inserted }
            .sorted { $0.path < $1.path }
    }

    private func invalid(_ path: String, _ message: String, at location: SourceLocation) -> Finding {
        Finding(rule: .invalidWorkflow, severity: .error, path: path, location: location, message: message)
    }

    private static func location(of error: YAMLLoadError) -> SourceLocation {
        switch error {
        case .syntax(let location?), .duplicateKey(let location?): return location
        default: return .start
        }
    }

    private static func describe(_ error: YAMLLoadError) -> String {
        switch error {
        case .syntax:
            return "The file is not valid YAML at this position."
        case .duplicateKey:
            return "This key appears more than once in the same mapping."
        case .tooDeep(let limit):
            return "The YAML is nested more than \(limit) levels deep; workflows are not."
        case .tooManyNodes(let limit):
            return "The YAML expands to more than \(limit) nodes (through aliases); it was not checked."
        case .empty:
            return "The file is empty."
        }
    }
}
