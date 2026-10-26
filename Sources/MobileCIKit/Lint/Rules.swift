import Foundation

/// Collects the findings of one workflow file.
struct RuleContext {
    let path: String
    let workflow: Workflow
    private(set) var findings: [Finding] = []

    init(path: String, workflow: Workflow) {
        self.path = path
        self.workflow = workflow
    }

    mutating func report(_ rule: RuleID, at location: SourceLocation, _ message: String) {
        findings.append(Finding(rule: rule, severity: rule.defaultSeverity, path: path, location: location, message: message))
    }
}

/// The checks behind each ``RuleID``. Each function looks at one aspect of the workflow.
enum Rules {
    static func checkAll(_ context: inout RuleContext) {
        checkUnpinnedActions(&context)
        checkMacOSJobs(&context)
        checkXcodeSelection(&context)
        checkPermissions(&context)
        checkScripts(&context)
        checkPullRequestTarget(&context)
        checkContinueOnError(&context)
        checkSetupActions(&context)
    }

    /// Text from the file that may appear in a message: a short, printable identifier. Anything
    /// else is replaced by a generic description.
    static func quoted(_ text: String, allowed: CharacterSet, fallback: String) -> String {
        guard !text.isEmpty, text.count <= 120, text.unicodeScalars.allSatisfy(allowed.contains) else {
            return fallback
        }
        return "`\(text)`"
    }

    static let referenceCharacters = CharacterSet(charactersIn:
        "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789-_./@:")

    static let labelCharacters = CharacterSet(charactersIn:
        "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789-_.")

    // MARK: MCI001

    static func checkUnpinnedActions(_ context: inout RuleContext) {
        for job in context.workflow.jobs {
            if let uses = job.reusableWorkflow {
                checkReference(uses, in: &context)
            }
            for step in job.steps {
                if let uses = step.uses { checkReference(uses, in: &context) }
            }
        }
    }

    private static func checkReference(_ node: YAMLValue, in context: inout RuleContext) {
        guard let reference = node.string?.trimmingCharacters(in: .whitespaces), !reference.hasPrefix("./") else {
            return
        }
        if reference.hasPrefix("docker://") {
            guard !reference.contains("@sha256:") else { return }
            let shown = quoted(reference, allowed: referenceCharacters, fallback: "This Docker image")
            context.report(.unpinnedAction, at: node.location, "\(shown) is pulled by tag; pin it to an `@sha256:` digest.")
            return
        }
        let parts = reference.split(separator: "@", maxSplits: 1, omittingEmptySubsequences: false)
        guard parts.count == 2 else { return }
        let ref = parts[1]
        let isSHA = ref.count == 40 && ref.allSatisfy(\.isHexDigit)
        guard !isSHA else { return }
        let shown = quoted(reference, allowed: referenceCharacters, fallback: "This action reference")
        context.report(.unpinnedAction, at: node.location,
                       "\(shown) is pinned to a tag or branch, which can be moved to other code; pin it to a full commit SHA.")
    }

    // MARK: MCI002, MCI003, MCI004

    static func checkMacOSJobs(_ context: inout RuleContext) {
        let workflow = context.workflow
        let pushOrPullRequest = !workflow.triggers.isDisjoint(with: ["push", "pull_request", "pull_request_target"])
        for job in workflow.jobs where job.reusableWorkflow == nil && job.runsOnMacOS {
            if job.node["timeout-minutes"] == nil {
                context.report(.macOSJobWithoutTimeout, at: job.idLocation,
                               "Job \(jobName(job)) runs on macOS without timeout-minutes; a hung build or simulator keeps it running for up to 6 hours.")
            }
            if pushOrPullRequest, !workflow.hasConcurrency, job.node["concurrency"] == nil {
                context.report(.macOSWorkflowWithoutConcurrency, at: job.idLocation,
                               "Job \(jobName(job)) runs on macOS but no concurrency group cancels superseded runs of this workflow.")
            }
            for (label, location) in job.runnerLabels where label.lowercased().hasPrefix("macos-latest") {
                let shown = quoted(label, allowed: labelCharacters, fallback: "macos-latest")
                context.report(.floatingMacOSImage, at: location,
                               "\(shown) moves to a new macOS image and default Xcode without a change in this repository; use a versioned label such as `macos-26`.")
            }
        }
    }

    static func jobName(_ job: Job) -> String {
        quoted(job.id, allowed: labelCharacters, fallback: "(unnamed)")
    }
}
