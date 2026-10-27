@testable import MobileCIKit
import Testing

/// Workflows a pull request could add to make linting slow. Each one stays under the 1 MiB file
/// and 200,000 node limits; the time limit is far above what the files take and far below what
/// work that grows with the product of two parts of the file takes.
@Suite struct LintCostTests {
    static let header = "name: p\non: pull_request\npermissions:\n  contents: read\n"
    static let timeLimit = Duration.seconds(10)

    /// `count` mapping members `X0: y`, `X1: y`, ... indented by `indent`.
    static func filler(_ count: Int, indent: String = "") -> String {
        (0..<count).map { "\(indent)X\($0): y\n" }.joined()
    }

    /// A flow sequence of `count` steps that run `x`, followed by `last`.
    static func steps(_ count: Int, last: [String] = []) -> String {
        "[" + (Array(repeating: "{run: x}", count: count) + last).joined(separator: ", ") + "]"
    }

    /// 30,000 workflow `env:` names share one untrusted value through an alias, and 30,000 steps
    /// without `env:` sit under them. A step adds only its own names to the scopes around it, so
    /// the workflow names are not copied for every step.
    @Test func manyEnvNamesOverManySteps() {
        let count = 30000
        let names = (0..<count).map { "  W\($0): *a\n" }.joined()
        let last = ["{run: \"echo ${{ env.W\(count - 1) }}\"}", "{run: \"echo ${{ toJSON(env) }}\"}"]
        let yaml = Self.header + "env:\n  A: &a ${{ github.head_ref }}\n" + names
            + "jobs:\n  a:\n    runs-on: ubuntu-24.04\n    steps: " + Self.steps(count, last: last) + "\n"
        var findings: [Finding] = []
        let elapsed = ContinuousClock().measure { findings = lint(yaml) }
        #expect(findings.filter { $0.rule == .untrustedInputInScript }.count == 2)
        #expect(elapsed < Self.timeLimit)
    }

    /// 20,000 workflow keys, 20,000 job keys and 35,000 steps: the `defaults.run.shell` of the
    /// workflow and the job is looked up once, not again for every step.
    @Test func manyStepsUnderLargeWorkflowAndJob() {
        let yaml = Self.header + Self.filler(20000) + "jobs:\n  a:\n    runs-on: ubuntu-24.04\n"
            + Self.filler(20000, indent: "    ") + "    steps: " + Self.steps(35000) + "\n"
        var findings: [Finding] = []
        let elapsed = ContinuousClock().measure { findings = lint(yaml) }
        #expect(findings.isEmpty)
        #expect(elapsed < Self.timeLimit)
    }

    /// 30,000 workflow keys and 30,000 macOS jobs: whether the workflow sets `permissions` and
    /// `concurrency` is looked up once, not again for every job.
    @Test func manyJobsUnderLargeWorkflow() {
        let count = 30000
        let jobs = (0..<count).map { "  j\($0): {runs-on: macos-26}\n" }.joined()
        let yaml = "name: p\non: pull_request\n" + Self.filler(count) + "jobs:\n" + jobs
        var findings: [Finding] = []
        let elapsed = ContinuousClock().measure { findings = lint(yaml) }
        #expect(findings.filter { $0.rule == .defaultTokenPermissions }.count == count)
        #expect(findings.filter { $0.rule == .macOSWorkflowWithoutConcurrency }.count == count)
        #expect(elapsed < Self.timeLimit)
    }
}
