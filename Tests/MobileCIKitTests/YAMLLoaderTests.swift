import Foundation
@testable import MobileCIKit
import Testing

struct YAMLLoaderTests {
    @Test func keepsScalarsAsTextWithLocations() throws {
        let root = try YAMLLoader.load("on: push\nyes: 1.10\njobs:\n  a: {}\n").get()
        #expect(root["on"]?.string == "push")
        #expect(root["yes"]?.string == "1.10")
        #expect(root.member("jobs")?.keyLocation == SourceLocation(line: 3, column: 1))
        #expect(root["jobs"]?.member("a")?.keyLocation == SourceLocation(line: 4, column: 3))
    }

    @Test func literalBlocksStartOnTheLineAfterTheIndicator() throws {
        let root = try YAMLLoader.load("run: |\n  echo one\n  echo two\nplain: x\n").get()
        #expect(root["run"]?.location.line == 2)
        #expect(root["plain"]?.location.line == 4)
    }

    @Test func syntaxErrorsCarryOnlyAPosition() {
        let secret = "ghp_" + String(repeating: "a", count: 36)
        let result = YAMLLoader.load("token: \(secret)\njobs: [unclosed\n")
        guard case .failure(.syntax(let location)) = result else {
            Issue.record("expected a syntax error, got \(result)")
            return
        }
        #expect(location != nil)
        let finding = WorkflowLinter().lint(text: "token: \(secret)\njobs: [unclosed\n", path: "w.yml")
        #expect(finding.map(\.rule) == [.invalidWorkflow])
        #expect(finding.allSatisfy { !$0.message.contains(secret) && !$0.message.contains("token") })
    }

    @Test func duplicateKeysAreRefused() {
        let result = YAMLLoader.load("jobs: {}\njobs: {}\n")
        #expect(result == .failure(.duplicateKey("jobs")))
    }

    @Test func nestingPastTheLimitIsRefused() {
        let depth = YAMLLoader.maximumDepth + 2
        let text = "a: " + String(repeating: "[", count: depth) + String(repeating: "]", count: depth)
        #expect(YAMLLoader.load(text) == .failure(.tooDeep(limit: YAMLLoader.maximumDepth)))
    }

    /// libyaml stops at 1,000 levels; deeper input is a syntax error, not a stack overflow on a
    /// test runner thread.
    @Test func veryDeepNestingFailsWithoutCrashing() {
        let text = String(repeating: "[", count: 5_000) + String(repeating: "]", count: 5_000)
        guard case .failure = YAMLLoader.load(text) else {
            Issue.record("expected a failure")
            return
        }
        let blocks = (0..<1_500).map { String(repeating: " ", count: $0) + "a:" }.joined(separator: "\n")
        guard case .failure = YAMLLoader.load(blocks) else {
            Issue.record("expected a failure")
            return
        }
    }

    /// Ten levels of ten aliases describe 10^10 nodes in a few hundred bytes.
    @Test func aliasExpansionStopsAtTheNodeLimit() {
        var text = "a: &a [x, x, x, x, x, x, x, x, x, x]\n"
        var previous = "a"
        for level in 0..<10 {
            let name = "l\(level)"
            text += "\(name): &\(name) [" + Array(repeating: "*\(previous)", count: 10).joined(separator: ", ") + "]\n"
            previous = name
        }
        let start = Date()
        #expect(YAMLLoader.load(text) == .failure(.tooManyNodes(limit: YAMLLoader.maximumNodes)))
        #expect(Date().timeIntervalSince(start) < 10)
        let findings = WorkflowLinter().lint(text: text, path: "laughs.yml")
        #expect(findings.map(\.rule) == [.invalidWorkflow])
    }

    @Test func emptyDocument() {
        #expect(YAMLLoader.load("") == .failure(.empty))
        #expect(YAMLLoader.load("# only a comment\n") == .failure(.empty))
    }
}

extension Result where Success == YAMLValue, Failure == YAMLLoadError {
    static func == (lhs: Self, rhs: Self) -> Bool {
        switch (lhs, rhs) {
        case (.failure(let left), .failure(let right)): return left == right
        default: return false
        }
    }
}
