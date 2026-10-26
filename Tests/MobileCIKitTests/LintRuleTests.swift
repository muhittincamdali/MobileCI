@testable import MobileCIKit
import Testing

/// Lints `yaml` and returns the findings.
func lint(_ yaml: String, disabled: Set<RuleID> = []) -> [Finding] {
    WorkflowLinter(disabledRules: disabled).lint(text: yaml, path: "w.yml")
}

func rules(_ yaml: String) -> Set<RuleID> {
    Set(lint(yaml).map(\.rule))
}

/// A workflow that passes every rule, used as the base the tests change one thing in.
let cleanWorkflow = """
name: iOS
on: [push, pull_request]
permissions:
  contents: read
concurrency:
  group: ${{ github.workflow }}-${{ github.ref }}
  cancel-in-progress: true
jobs:
  test:
    runs-on: macos-26
    timeout-minutes: 30
    env:
      DEVELOPER_DIR: /Applications/Xcode_26.6.app/Contents/Developer
    steps:
      - uses: actions/checkout@3d3c42e5aac5ba805825da76410c181273ba90b1 # v7.0.1
        with:
          persist-credentials: false
      - run: |
          set -o pipefail
          xcodebuild test -scheme App | xcbeautify
"""

struct LintRuleTests {
    @Test func cleanWorkflowHasNoFindings() {
        #expect(lint(cleanWorkflow).isEmpty)
    }

    @Test func notAWorkflow() {
        #expect(rules("name: x\nruns:\n  using: composite\n") == [.invalidWorkflow])
        #expect(rules("- a\n- b\n") == [.invalidWorkflow])
    }

    // MARK: MCI001

    @Test func tagsAndBranchesAreUnpinned() {
        let yaml = cleanWorkflow.replacingOccurrences(of: "3d3c42e5aac5ba805825da76410c181273ba90b1", with: "v7")
        let finding = lint(yaml).first { $0.rule == .unpinnedAction }
        #expect(finding?.location.line == 15)
        #expect(finding?.message.hasPrefix("`actions/checkout@v7`") == true)
    }

    @Test func pinnedLocalAndDigestReferencesPass() {
        let steps = """
              - uses: ./.github/actions/setup
              - uses: docker://alpine@sha256:1e014f84205d569a5cc3be4e108ca614055f7e21d11928946113ab3f36054801
              - uses: owner/repo/path@0123456789abcdef0123456789ABCDEF01234567
        """
        #expect(!rules(cleanWorkflow + "\n" + steps).contains(.unpinnedAction))
        #expect(rules(cleanWorkflow + "\n      - uses: docker://alpine:3.22\n").contains(.unpinnedAction))
    }

    /// A registry login written into the reference must not be copied into the report.
    @Test func credentialsInReferencesAreNotPrinted() {
        let docker = lint(cleanWorkflow + "\n      - uses: docker://deploy:s3cr3tT0ken@registry.example.com/app:1.0\n")
            .first { $0.rule == .unpinnedAction }
        #expect(docker?.message.hasPrefix("This Docker image is pulled by tag") == true)
        #expect(docker?.message.contains("s3cr3tT0ken") == false)
        let plain = lint(cleanWorkflow + "\n      - uses: docker://ghcr.io/owner/app:1.0\n").first { $0.rule == .unpinnedAction }
        #expect(plain?.message.hasPrefix("`docker://ghcr.io/owner/app:1.0`") == true)
        let action = lint(cleanWorkflow + "\n      - uses: https://user:t0ken@example.com/owner/repo@v1\n").first { $0.rule == .unpinnedAction }
        #expect(action?.message.contains("t0ken") == false)
    }

    @Test func duplicateKeysAreReportedWithoutTheirName() {
        let key = "TOKEN_" + String(repeating: "a1b2", count: 9)
        let finding = lint("on: push\njobs:\n  build:\n    env:\n      \(key): a\n      \(key): b\n").first
        #expect(finding?.rule == .invalidWorkflow)
        #expect(finding?.message == "This key appears more than once in the same mapping.")
        #expect(finding?.location.line == 5)
    }

    @Test func reusableWorkflowCallsArePinnedToo() {
        let yaml = cleanWorkflow + "\n  shared:\n    uses: owner/repo/.github/workflows/ci.yml@main\n"
        #expect(lint(yaml).filter { $0.rule == .unpinnedAction }.count == 1)
    }

    @Test func unexpectedTextIsNotRepeated() {
        let yaml = cleanWorkflow + "\n      - uses: \"owner/repo@v1\\u001b[2J\"\n"
        let finding = lint(yaml).first { $0.rule == .unpinnedAction }
        #expect(finding?.message.hasPrefix("This action reference") == true)
    }

    // MARK: MCI002, MCI003, MCI004

    @Test func macOSJobsNeedATimeout() {
        let yaml = cleanWorkflow.replacingOccurrences(of: "    timeout-minutes: 30\n", with: "")
        #expect(rules(yaml) == [.macOSJobWithoutTimeout])
        let linux = yaml.replacingOccurrences(of: "macos-26", with: "ubuntu-24.04")
        #expect(rules(linux).isEmpty)
    }

    @Test func macOSWorkflowsNeedConcurrency() {
        let yaml = cleanWorkflow.replacingOccurrences(of: """
        concurrency:
          group: ${{ github.workflow }}-${{ github.ref }}
          cancel-in-progress: true

        """, with: "")
        #expect(rules(yaml) == [.macOSWorkflowWithoutConcurrency])
        let manual = yaml.replacingOccurrences(of: "on: [push, pull_request]", with: "on: workflow_dispatch")
        #expect(rules(manual).isEmpty)
    }

    @Test func macOSLatestDrifts() {
        let yaml = cleanWorkflow.replacingOccurrences(of: "runs-on: macos-26", with: "runs-on: macos-latest")
        #expect(rules(yaml) == [.floatingMacOSImage])
    }

    @Test func matrixRunnerLabelsAreResolved() {
        let yaml = cleanWorkflow.replacingOccurrences(of: "    runs-on: macos-26\n", with: """
            runs-on: ${{ matrix.os }}
            strategy:
              matrix:
                os: [ubuntu-24.04, macos-latest]

        """)
        let finding = lint(yaml).first { $0.rule == .floatingMacOSImage }
        #expect(finding?.location.line == 13)
    }

    @Test func selfHostedMacOSLabelCounts() {
        let yaml = cleanWorkflow
            .replacingOccurrences(of: "runs-on: macos-26", with: "runs-on: [self-hosted, macOS, ARM64]")
            .replacingOccurrences(of: "    timeout-minutes: 30\n", with: "")
        #expect(rules(yaml) == [.macOSJobWithoutTimeout])
    }

    // MARK: MCI005

    @Test func xcodeMustBeSelected() {
        let yaml = cleanWorkflow.replacingOccurrences(of: """
            env:
              DEVELOPER_DIR: /Applications/Xcode_26.6.app/Contents/Developer

        """, with: "")
        #expect(rules(yaml) == [.xcodeNotSelected])
        let selected = yaml.replacingOccurrences(of: "set -o pipefail", with: "set -o pipefail\n          sudo xcode-select -s /Applications/Xcode_26.6.app")
        #expect(rules(selected).isEmpty)
        let action = yaml.replacingOccurrences(of: "      - run: |", with: """
              - uses: maxim-lobanov/setup-xcode@60606e260d2fc5762a71e64e74b2174e8ea3c8bd # v1.6.0
              - run: |
        """)
        #expect(rules(action).isEmpty)
    }

    // MARK: MCI006, MCI007

    @Test func missingPermissionsAreReportedPerJob() {
        let yaml = cleanWorkflow.replacingOccurrences(of: "permissions:\n  contents: read\n", with: "")
        #expect(rules(yaml) == [.defaultTokenPermissions])
        let perJob = yaml.replacingOccurrences(of: "    runs-on: macos-26\n", with: "    runs-on: macos-26\n    permissions: {}\n")
        #expect(rules(perJob).isEmpty)
    }

    @Test func writeAllIsAnError() {
        let yaml = cleanWorkflow.replacingOccurrences(of: "permissions:\n  contents: read\n", with: "permissions: write-all\n")
        let finding = lint(yaml).first { $0.rule == .writeAllPermissions }
        #expect(finding?.severity == .error)
        #expect(finding?.location.line == 3)
    }

    // MARK: MCI008, MCI011

    @Test(arguments: [
        "github.event.pull_request.title",
        "github.event['pull_request']['body']",
        "github.head_ref",
        "toJSON(github.event.pull_request)",
        "github.event.commits[0].message",
        "GITHUB.EVENT.ISSUE.TITLE",
        "github.event.workflow_run.head_branch"
    ])
    func untrustedInputInScripts(expression: String) {
        let yaml = cleanWorkflow + "\n      - run: echo \"${{ \(expression) }}\"\n"
        let finding = lint(yaml).first { $0.rule == .untrustedInputInScript }
        #expect(finding?.severity == .error)
        #expect(finding?.location.line == 21)
    }

    @Test(arguments: [
        "github.event.pull_request.number",
        "github.event.pull_request.head.sha",
        "github.sha",
        "contains('github.event.issue.title', 'x')",
        "inputs.title"
    ])
    func trustedExpressionsPass(expression: String) {
        let yaml = cleanWorkflow + "\n      - run: echo \"${{ \(expression) }}\"\n"
        #expect(!rules(yaml).contains(.untrustedInputInScript))
    }

    @Test func untrustedInputThroughEnvPasses() {
        let yaml = cleanWorkflow + """

              - env:
                  TITLE: ${{ github.event.pull_request.title }}
                run: echo "$TITLE"
        """
        #expect(lint(yaml).isEmpty)
    }

    /// `${{ env.TITLE }}` is replaced before the shell runs, so an untrusted value set in any
    /// `env:` scope is as dangerous as the event property itself.
    @Test(arguments: ["step", "job", "workflow"])
    func untrustedInputThroughEnvExpressionsIsReported(scope: String) {
        let assignment = "TITLE: ${{ github.event.pull_request.title }}"
        var yaml = cleanWorkflow + "\n      - run: echo \"${{ env.title }}\"\n"
        switch scope {
        case "step": yaml = cleanWorkflow + "\n      - env:\n          \(assignment)\n        run: echo \"${{ env.TITLE }}\"\n"
        case "job": yaml = yaml.replacingOccurrences(of: "    env:\n", with: "    env:\n      \(assignment)\n")
        default: yaml = "env:\n  \(assignment)\n" + yaml
        }
        let finding = lint(yaml).first { $0.rule == .untrustedInputInScript }
        #expect(finding?.message.contains("is set from `github.event.pull_request.title`") == true)
    }

    /// A step `env:` value that reads `env` again is evaluated against the job and workflow
    /// `env:`, so `B: ${{ env.A }}` carries an untrusted `A` into `${{ env.B }}`.
    @Test func untrustedInputThroughChainedEnvExpressionsIsReported() {
        let yaml = "env:\n  A: ${{ github.head_ref }}\n" + cleanWorkflow + """

              - env:
                  B: ${{ env.A }}
                run: echo "${{ env.B }}"
        """
        let finding = lint(yaml).first { $0.rule == .untrustedInputInScript }
        #expect(finding?.message.contains("is set from `github.head_ref`") == true)
        #expect(rules(yaml.replacingOccurrences(of: "${{ env.B }}", with: "${{ toJSON(env) }}")).contains(.untrustedInputInScript))
        #expect(!rules(yaml.replacingOccurrences(of: "${{ github.head_ref }}", with: "${{ github.sha }}")).contains(.untrustedInputInScript))
    }

    /// Inside one step `env:`, `${{ env.A }}` reads the job and workflow value of `A`, not the
    /// step's own `A`, so an untrusted step `A` does not reach `B`.
    @Test func chainedEnvExpressionsDoNotReadTheirOwnScope() {
        let yaml = cleanWorkflow + """

              - env:
                  A: ${{ github.head_ref }}
                  B: ${{ env.A }}
                run: echo "${{ env.B }}"
        """
        #expect(!rules(yaml).contains(.untrustedInputInScript))
    }

    /// GitHub does not offer the `env` context in a job `env:`, so `B: ${{ env.A }}` there is
    /// empty and an untrusted workflow `A` does not reach `B`.
    @Test func jobEnvValuesDoNotReadEnv() {
        let assignment = "B: ${{ env.A }}"
        let yaml = "env:\n  A: ${{ github.head_ref }}\n"
            + cleanWorkflow.replacingOccurrences(of: "    env:\n", with: "    env:\n      \(assignment)\n")
            + "\n      - run: echo \"${{ env.B }}\"\n"
        #expect(!rules(yaml).contains(.untrustedInputInScript))
    }

    /// Every `env:` value in three scopes reads the whole `env` context. Each scope is worked out
    /// once, so a pull request that adds such a file cannot hold the lint step until its job
    /// times out; following the values again for every member took minutes at 300 per scope.
    @Test func envValuesThatReadEnvAgainStayFast() {
        let count = 1000
        func members(_ prefix: String, indent: String) -> String {
            (0..<count).map { "\(indent)\(prefix)\($0): ${{ toJSON(env) }}\n" }.joined()
        }
        let yaml = "env:\n  T: ${{ github.head_ref }}\n" + members("W", indent: "  ")
            + cleanWorkflow.replacingOccurrences(of: "    env:\n", with: "    env:\n" + members("J", indent: "      "))
            + "\n      - env:\n" + members("S", indent: "          ")
            + "        run: echo \"${{ env.S\(count - 1) }}\"\n"
        var found: Set<RuleID> = []
        let elapsed = ContinuousClock().measure { found = rules(yaml) }
        #expect(found.contains(.untrustedInputInScript))
        #expect(elapsed < .seconds(10))
    }

    @Test func envExpressionsWithTrustedValuesPass() {
        let yaml = "env:\n  TITLE: ${{ github.event.pull_request.title }}\n" + cleanWorkflow + """

              - env:
                  TITLE: fixed text
                  SHA: ${{ github.sha }}
                run: echo "${{ env.TITLE }} ${{ env.SHA }} ${{ env.MISSING }}"
        """
        #expect(!rules(yaml).contains(.untrustedInputInScript))
        #expect(rules("env:\n  T: ${{ github.head_ref }}\n" + cleanWorkflow + "\n      - run: echo '${{ toJSON(env) }}'\n")
            .contains(.untrustedInputInScript))
    }

    @Test func githubScriptIsCheckedForInjection() {
        let yaml = cleanWorkflow + """

              - uses: actions/github-script@ed597411d8f924073f98dfc5c65a23a2325f34cd # v8.0.0
                with:
                  script: console.log("${{ github.event.issue.body }}")
        """
        #expect(rules(yaml) == [.untrustedInputInScript])
    }

    @Test func secretsInScriptsAreReportedOnTheirLine() {
        let yaml = cleanWorkflow.replacingOccurrences(of: "          set -o pipefail\n", with: "          set -o pipefail\n          echo ${{ secrets.MATCH_PASSWORD }} | fastlane match\n")
        let finding = lint(yaml).first { $0.rule == .secretInScript }
        #expect(finding?.location.line == 20)
        #expect(finding?.message.contains("`secrets.MATCH_PASSWORD`") == true)
    }

    // MARK: MCI009

    @Test func pullRequestTargetCheckoutOfHeadIsAnError() {
        let yaml = cleanWorkflow
            .replacingOccurrences(of: "on: [push, pull_request]", with: "on: pull_request_target")
            .replacingOccurrences(of: "          persist-credentials: false\n", with: "          persist-credentials: false\n          ref: ${{ github.event.pull_request.head.sha }}\n")
        #expect(rules(yaml) == [.pullRequestTargetCheckout])
        let base = yaml.replacingOccurrences(of: "on: pull_request_target", with: "on: pull_request")
        #expect(rules(base).isEmpty)
    }

    // MARK: MCI010

    @Test func continueOnErrorTrue() {
        let yaml = cleanWorkflow.replacingOccurrences(of: "      - run: |", with: "      - continue-on-error: true\n        run: |")
        #expect(rules(yaml) == [.continueOnError])
        let expression = yaml.replacingOccurrences(of: "continue-on-error: true", with: "continue-on-error: ${{ matrix.experimental }}")
        #expect(rules(expression).isEmpty)
    }

    // MARK: MCI012, MCI013, MCI014

    @Test func checkoutPersistingCredentialsIsANote() {
        let yaml = cleanWorkflow.replacingOccurrences(of: "        with:\n          persist-credentials: false\n", with: "")
        let finding = lint(yaml).first
        #expect(finding?.rule == .checkoutPersistsCredentials)
        #expect(finding?.severity == .note)
    }

    @Test func setupActionsNeedVersions() {
        let yaml = cleanWorkflow + """

              - uses: subosito/flutter-action@1a449444c387b1966244ae4d4f8c696479add0b2 # v2.23.0
                with:
                  channel: stable
              - uses: actions/setup-node@949feb2413d6458794dcd2491c4babbbce0c15c1 # v7.1.0
        """
        #expect(rules(yaml) == [.flutterVersionNotPinned, .nodeVersionNotPinned])
        let pinned = yaml
            .replacingOccurrences(of: "channel: stable", with: "flutter-version-file: pubspec.yaml")
            .replacingOccurrences(of: "# v7.1.0", with: "# v7.1.0\n        with:\n          node-version-file: .nvmrc")
        #expect(rules(pinned).isEmpty)
    }

    // MARK: MCI015

    @Test func pipesWithoutPipefail() {
        let yaml = cleanWorkflow.replacingOccurrences(of: "          set -o pipefail\n", with: "")
        let finding = lint(yaml).first
        #expect(finding?.rule == .pipeHidesBuildFailure)
        #expect(finding?.location.line == 19)
        let bash = yaml.replacingOccurrences(of: "      - run: |", with: "      - shell: bash\n        run: |")
        #expect(rules(bash).isEmpty)
        let defaults = yaml.replacingOccurrences(of: "jobs:\n", with: "defaults:\n  run:\n    shell: bash\njobs:\n")
        #expect(rules(defaults).isEmpty)
    }

    @Test func pipedToolDetection() {
        #expect(Rules.pipedTool(in: "xcodebuild test | xcbeautify") == "xcodebuild")
        #expect(Rules.pipedTool(in: "./gradlew assembleDebug 2>&1 | tee build.log") == "gradlew")
        #expect(Rules.pipedTool(in: "xcodebuild test || exit 1") == nil)
        #expect(Rules.pipedTool(in: "echo done | tee log") == nil)
        #expect(Rules.pipedTool(in: "xcodebuild test # | xcbeautify") == nil)
        #expect(Rules.pipedTool(in: "flutter test |& tee log") == "flutter")
        #expect(Rules.pipedTool(in: "xcodebuild|xcpretty") == "xcodebuild")
        #expect(Rules.pipedTool(in: "xcodebuild test|xcbeautify") == "xcodebuild")
        #expect(Rules.pipedTool(in: "cd ios&&xcodebuild test|xcpretty") == "xcodebuild")
        #expect(Rules.pipedTool(in: "xcodebuild test||exit 1") == nil)
        #expect(Rules.pipedTool(in: "./gradlew build 2>&1|tee log") == "gradlew")
    }

    @Test func continuationLinesAreJoined() {
        let script = "xcodebuild test \\\n  -scheme App \\\n  | xcpretty\necho ok"
        let lines = Rules.logicalLines(of: script)
        #expect(lines.count == 2)
        #expect(lines[0].lineCount == 3)
        #expect(Rules.pipedTool(in: lines[0].text) == "xcodebuild")
    }

    @Test func disabledRulesAreSkipped() {
        let yaml = cleanWorkflow.replacingOccurrences(of: "macos-26", with: "macos-latest")
        #expect(lint(yaml, disabled: [.floatingMacOSImage]).isEmpty)
    }
}
