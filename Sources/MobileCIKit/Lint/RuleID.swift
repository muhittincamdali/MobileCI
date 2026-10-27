import Foundation

/// The lint rules. Identifiers are stable: they are used in suppression comments, in
/// `--disable` and in SARIF reports.
public enum RuleID: String, Sendable, Codable, CaseIterable, Comparable {
    case invalidWorkflow = "MCI000"
    case unpinnedAction = "MCI001"
    case macOSJobWithoutTimeout = "MCI002"
    case macOSWorkflowWithoutConcurrency = "MCI003"
    case floatingMacOSImage = "MCI004"
    case xcodeNotSelected = "MCI005"
    case defaultTokenPermissions = "MCI006"
    case writeAllPermissions = "MCI007"
    case untrustedInputInScript = "MCI008"
    case pullRequestTargetCheckout = "MCI009"
    case continueOnError = "MCI010"
    case secretInScript = "MCI011"
    case checkoutPersistsCredentials = "MCI012"
    case flutterVersionNotPinned = "MCI013"
    case nodeVersionNotPinned = "MCI014"
    case pipeHidesBuildFailure = "MCI015"

    public static func < (lhs: RuleID, rhs: RuleID) -> Bool {
        lhs.rawValue < rhs.rawValue
    }

    /// Reads `MCI001` or the rule's name, such as `unpinned-action`, ignoring case.
    public init?(identifier: String) {
        let text = identifier.trimmingCharacters(in: .whitespaces).lowercased()
        guard let rule = RuleID.allCases.first(where: {
            $0.rawValue.lowercased() == text || $0.name == text
        }) else { return nil }
        self = rule
    }

    /// A short kebab-case name.
    public var name: String {
        switch self {
        case .invalidWorkflow: return "invalid-workflow"
        case .unpinnedAction: return "unpinned-action"
        case .macOSJobWithoutTimeout: return "macos-job-without-timeout"
        case .macOSWorkflowWithoutConcurrency: return "macos-workflow-without-concurrency"
        case .floatingMacOSImage: return "floating-macos-image"
        case .xcodeNotSelected: return "xcode-not-selected"
        case .defaultTokenPermissions: return "default-token-permissions"
        case .writeAllPermissions: return "write-all-permissions"
        case .untrustedInputInScript: return "untrusted-input-in-script"
        case .pullRequestTargetCheckout: return "pull-request-target-checkout"
        case .continueOnError: return "continue-on-error"
        case .secretInScript: return "secret-in-script"
        case .checkoutPersistsCredentials: return "checkout-persists-credentials"
        case .flutterVersionNotPinned: return "flutter-version-not-pinned"
        case .nodeVersionNotPinned: return "node-version-not-pinned"
        case .pipeHidesBuildFailure: return "pipe-hides-build-failure"
        }
    }

    public var defaultSeverity: Severity {
        switch self {
        case .invalidWorkflow, .writeAllPermissions, .untrustedInputInScript,
             .pullRequestTargetCheckout, .pipeHidesBuildFailure:
            return .error
        case .checkoutPersistsCredentials:
            return .note
        default:
            return .warning
        }
    }

    /// One sentence: what the rule finds.
    public var summary: String {
        switch self {
        case .invalidWorkflow:
            return "The file cannot be read as a workflow: it is not UTF-8 YAML, is too large or too deeply nested, or has no jobs."
        case .unpinnedAction:
            return "An action or reusable workflow is referenced by a tag or branch instead of a full commit SHA."
        case .macOSJobWithoutTimeout:
            return "A job on a macOS runner has no timeout-minutes, so a hung simulator can run for six hours."
        case .macOSWorkflowWithoutConcurrency:
            return "A workflow with macOS jobs has no concurrency group, so every push keeps its older runs going."
        case .floatingMacOSImage:
            return "A job runs on macos-latest, whose image (and default Xcode) changes without a change in the repository."
        case .xcodeNotSelected:
            return "A job builds with Xcode without selecting a version, so it uses whatever the runner image defaults to."
        case .defaultTokenPermissions:
            return "Neither the workflow nor the job sets permissions, so GITHUB_TOKEN gets the repository's default, which can be read-write."
        case .writeAllPermissions:
            return "The workflow or a job grants write-all permissions to GITHUB_TOKEN."
        case .untrustedInputInScript:
            return "Text an outside contributor controls (a pull request title, a branch name, a comment) is expanded inside a script."
        case .pullRequestTargetCheckout:
            return "A pull_request_target workflow checks out the pull request's code, which then runs with the base repository's secrets."
        case .continueOnError:
            return "A job or step sets continue-on-error: true, so its failure leaves the run green."
        case .secretInScript:
            return "A secret is expanded directly inside a script instead of being passed through env."
        case .checkoutPersistsCredentials:
            return "actions/checkout leaves the token in .git/config for every later step."
        case .flutterVersionNotPinned:
            return "subosito/flutter-action has neither flutter-version nor flutter-version-file, so each run takes the newest Flutter."
        case .nodeVersionNotPinned:
            return "actions/setup-node has neither node-version nor node-version-file, so the runner's preinstalled Node is used."
        case .pipeHidesBuildFailure:
            return "xcodebuild (or a Gradle, Flutter or fastlane command) is piped into a formatter without pipefail, so its failure is lost."
        }
    }

    /// What to change.
    public var fix: String {
        switch self {
        case .invalidWorkflow:
            return "Fix the YAML at the reported position; run `mobileci lint` again."
        case .unpinnedAction:
            return "Use the 40-character commit SHA of the release and keep the tag in a comment: `uses: actions/checkout@<sha> # v7.0.1`."
        case .macOSJobWithoutTimeout:
            return "Add `timeout-minutes:` to the job (30–60 is typical for build and test)."
        case .macOSWorkflowWithoutConcurrency:
            return "Add `concurrency: { group: ${{ github.workflow }}-${{ github.ref }}, cancel-in-progress: true }`."
        case .floatingMacOSImage:
            return "Use a versioned label such as `macos-26` and select the Xcode version explicitly."
        case .xcodeNotSelected:
            return "Set `DEVELOPER_DIR: /Applications/Xcode_26.6.app/Contents/Developer` in the job's env, or run `sudo xcode-select -s` in a step."
        case .defaultTokenPermissions:
            return "Add `permissions: contents: read` at the top of the workflow and widen it per job only where needed."
        case .writeAllPermissions:
            return "List only the scopes the job needs, such as `contents: write` or `pull-requests: write`."
        case .untrustedInputInScript:
            return "Pass the value through `env:` and use the variable in the script: `env: { TITLE: ${{ github.event.pull_request.title }} }`, then `\"$TITLE\"`."
        case .pullRequestTargetCheckout:
            return "Use `pull_request` for building contributed code; keep `pull_request_target` for jobs that never run it."
        case .continueOnError:
            return "Remove it, or limit it to a step whose result is reported elsewhere."
        case .secretInScript:
            return "Map the secret to an environment variable of the step and use the variable in the script."
        case .checkoutPersistsCredentials:
            return "Add `with: { persist-credentials: false }` unless a later step pushes with that token."
        case .flutterVersionNotPinned:
            return "Add `flutter-version: 3.47.8`, or `flutter-version-file: pubspec.yaml` with an exact `environment: flutter:` version."
        case .nodeVersionNotPinned:
            return "Add `node-version: 24` or `node-version-file: .nvmrc`."
        case .pipeHidesBuildFailure:
            return "Start the script with `set -o pipefail`, or set `shell: bash` (GitHub then runs bash with -o pipefail)."
        }
    }
}
