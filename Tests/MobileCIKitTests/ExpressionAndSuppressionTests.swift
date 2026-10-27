@testable import MobileCIKit
import Testing

struct ExpressionTests {
    @Test func findsExpressionsWithTheirLines() {
        let text = "a ${{ x }}\nb\n${{ y\n }} ${{ z }}"
        #expect(Expressions.occurrences(in: text) == [
            .init(body: " x ", lineOffset: 0),
            .init(body: " y\n ", lineOffset: 2),
            .init(body: " z ", lineOffset: 3)
        ])
    }

    @Test func unterminatedExpressionEndsTheScan() {
        #expect(Expressions.occurrences(in: "${{ a }} ${{ b").map(\.body) == [" a "])
    }

    @Test func propertyPathsAreNormalised() {
        #expect(Expressions.propertyPaths(in: "github.event['pull_request'][\"title\"]") == ["github.event.pull_request.title"])
        #expect(Expressions.propertyPaths(in: "github.event.commits[0].message") == ["github.event.commits.*.message"])
        #expect(Expressions.propertyPaths(in: "format('{0} {1}', github.sha, env.X)") == ["format", "github.sha", "env.X"])
        #expect(Expressions.propertyPaths(in: "contains('github.event.issue.title', x)") == ["contains", "x"])
    }

    @Test func objectsThatContainUntrustedTextAreUntrusted() {
        #expect(UntrustedInput.isUntrusted("github"))
        #expect(UntrustedInput.isUntrusted("github.event"))
        #expect(UntrustedInput.isUntrusted("github.event.pull_request"))
        #expect(UntrustedInput.isUntrusted("github.event.pages.*.page_name"))
        #expect(UntrustedInput.isUntrusted("github.event.pull_request.head.ref.length"))
        #expect(!UntrustedInput.isUntrusted("github.event.pull_request.head.sha"))
        #expect(!UntrustedInput.isUntrusted("github.repository"))
        #expect(!UntrustedInput.isUntrusted("matrix.os"))
    }
}

struct SuppressionTests {
    let unpinned = cleanWorkflow.replacingOccurrences(of: "3d3c42e5aac5ba805825da76410c181273ba90b1 # v7.0.1", with: "v7")

    @Test func sameLineAndLineAbove() {
        let sameLine = unpinned.replacingOccurrences(of: "actions/checkout@v7", with: "actions/checkout@v7 # mobileci-ignore MCI001")
        #expect(lint(sameLine).isEmpty)
        let above = unpinned.replacingOccurrences(of: "      - uses: actions/checkout@v7", with: "      # mobileci-ignore: unpinned-action\n      - uses: actions/checkout@v7")
        #expect(lint(above).isEmpty)
    }

    @Test func otherRulesStayActive() {
        let text = unpinned.replacingOccurrences(of: "actions/checkout@v7", with: "actions/checkout@v7 # mobileci-ignore MCI012")
        #expect(rules(text) == [.unpinnedAction])
    }

    @Test func wholeFile() {
        #expect(lint("# mobileci-ignore-file MCI001, MCI004\n" + unpinned.replacingOccurrences(of: "macos-26", with: "macos-latest")).isEmpty)
    }

    @Test func commentWithoutRulesSilencesNothing() {
        let text = unpinned.replacingOccurrences(of: "actions/checkout@v7", with: "actions/checkout@v7 # mobileci-ignore")
        #expect(rules(text) == [.unpinnedAction])
        let unknown = unpinned.replacingOccurrences(of: "actions/checkout@v7", with: "actions/checkout@v7 # mobileci-ignore MCI999")
        #expect(rules(unknown) == [.unpinnedAction])
    }

    @Test func hashInsideAValueBeforeTheComment() {
        let text = unpinned.replacingOccurrences(of: "actions/checkout@v7", with: "\"actions/checkout@v7\" # see #12 # mobileci-ignore MCI001")
        #expect(lint(text).isEmpty)
    }
}
