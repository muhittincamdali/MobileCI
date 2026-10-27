import Foundation
import MobileCIKit
import Observation

/// The text being checked and its findings.
@MainActor
@Observable
final class CheckModel {
    var sample: Sample {
        didSet { text = sample.text }
    }

    var text: String {
        didSet { findings = Self.check(text) }
    }

    private(set) var findings: [Finding]

    init(sample: Sample = .firstWorkflow) {
        self.sample = sample
        self.text = sample.text
        self.findings = Self.check(sample.text)
    }

    var summary: String {
        guard !findings.isEmpty else { return "No findings" }
        let errors = findings.filter { $0.severity == .error }.count
        let warnings = findings.filter { $0.severity == .warning }.count
        let notes = findings.count - errors - warnings
        return [(errors, "error"), (warnings, "warning"), (notes, "note")]
            .filter { $0.0 > 0 }
            .map { "\($0.0) \($0.1)\($0.0 == 1 ? "" : "s")" }
            .joined(separator: " · ")
    }

    static func check(_ text: String) -> [Finding] {
        WorkflowLinter().lint(text: text, path: "workflow.yml")
    }
}

/// `Version 1.0.0 (1)` from the bundle's Info.plist; `mobileci version bump` changes it.
enum AppVersion {
    static func label(info: [String: Any]?) -> String {
        let version = info?["CFBundleShortVersionString"] as? String ?? "?"
        let build = info?["CFBundleVersion"] as? String ?? "?"
        return "Version \(version) (\(build))"
    }
}
