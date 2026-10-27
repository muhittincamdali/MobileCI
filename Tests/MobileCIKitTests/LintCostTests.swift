@testable import MobileCIKit
import Testing

/// Workflows a pull request could add to make linting slow. Each one stays under the 1 MiB file
/// and 200,000 node limits; the time limit is far above what the files take and far below what
/// work that grows with the product of two parts of the file takes.
@Suite struct LintCostTests {
    static let header = "name: p\non: pull_request\npermissions:\n  contents: read\n"
    static let timeLimit = Duration.seconds(10)

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
}
