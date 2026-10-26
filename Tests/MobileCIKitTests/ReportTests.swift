import Foundation
@testable import MobileCIKit
import Testing

struct ReportTests {
    let finding = Finding(rule: .unpinnedAction, severity: .warning, path: ".github/workflows/ios.yml",
                          location: SourceLocation(line: 12, column: 9), message: "`actions/checkout@v4` is pinned to a tag.")

    @Test func textReport() {
        let text = ReportFormat.text.render([finding], filesChecked: 2)
        #expect(text == """
        .github/workflows/ios.yml:12:9: warning[MCI001] `actions/checkout@v4` is pinned to a tag.
        2 files checked: 0 error(s), 1 warning(s), 0 note(s).

        """)
    }

    /// A file name can hold a carriage return or an escape sequence that would rewrite the
    /// terminal line; the report prints `?` instead.
    @Test func controlCharactersInPathsAreReplaced() {
        let spoof = Finding(rule: .continueOnError, severity: .warning, path: "a\r\u{1B}[32mok.yml\u{202E}",
                            location: .start, message: "m")
        let text = ReportFormat.text.render([spoof], filesChecked: 1)
        #expect(text.hasPrefix("a??[32mok.yml?:1:1:"))
        #expect(!text.contains("\u{1B}") && !text.contains("\r") && !text.contains("\u{202E}"))
    }

    /// A newline in a value would start a new workflow command on the runner.
    @Test func githubCommandsCannotBeInjected() {
        let hostile = Finding(rule: .invalidWorkflow, severity: .error, path: "x,line=1::\n::add-mask::y.yml",
                              location: .start, message: "first\n::set-output name=a::b 100%")
        let output = ReportFormat.github.render([hostile], filesChecked: 1)
        #expect(output.split(separator: "\n").count == 1)
        #expect(output == "::error file=x%2Cline=1%3A%3A%0A%3A%3Aadd-mask%3A%3Ay.yml,line=1,col=1,title=MCI000 invalid-workflow::first%0A::set-output name=a::b 100%25\n")
    }

    @Test func noteBecomesNotice() {
        let note = Finding(rule: .checkoutPersistsCredentials, severity: .note, path: "w.yml", location: .start, message: "m")
        #expect(ReportFormat.github.render([note], filesChecked: 1).hasPrefix("::notice "))
    }

    @Test func jsonReportDecodes() throws {
        let data = Data(ReportFormat.json.render([finding], filesChecked: 3).utf8)
        let object = try #require(try JSONSerialization.jsonObject(with: data) as? [String: Any])
        let summary = try #require(object["summary"] as? [String: Int])
        #expect(summary == ["files": 3, "errors": 0, "warnings": 1, "notes": 0])
        let first = try #require((object["findings"] as? [[String: Any]])?.first)
        #expect(first["rule"] as? String == "MCI001")
        #expect(first["name"] as? String == "unpinned-action")
        #expect(first["line"] as? Int == 12)
    }

    @Test func sarifListsEveryRuleAndPointsResultsAtThem() throws {
        let data = Data(ReportFormat.sarif.render([finding], filesChecked: 1).utf8)
        let log = try #require(try JSONSerialization.jsonObject(with: data) as? [String: Any])
        #expect(log["version"] as? String == "2.1.0")
        let run = try #require((log["runs"] as? [[String: Any]])?.first)
        let driver = try #require((run["tool"] as? [String: Any])?["driver"] as? [String: Any])
        let rules = try #require(driver["rules"] as? [[String: Any]])
        #expect(rules.count == RuleID.allCases.count)
        let result = try #require((run["results"] as? [[String: Any]])?.first)
        let index = try #require(result["ruleIndex"] as? Int)
        #expect(rules[index]["id"] as? String == "MCI001")
        #expect(result["level"] as? String == "warning")
    }

    @Test func sarifURIsArePercentEncoded() {
        #expect(SARIFReport.uri(for: ".github/workflows/my ci.yml") == ".github/workflows/my%20ci.yml")
        #expect(SARIFReport.uri(for: "ş#?.yml") == "%C5%9F%23%3F.yml")
    }

    @Test func rulesHaveUniqueNamesAndParseBack() {
        #expect(Set(RuleID.allCases.map(\.name)).count == RuleID.allCases.count)
        for rule in RuleID.allCases {
            #expect(RuleID(identifier: rule.rawValue.lowercased()) == rule)
            #expect(RuleID(identifier: " \(rule.name) ") == rule)
            #expect(!rule.summary.isEmpty && !rule.fix.isEmpty)
        }
        #expect(RuleID(identifier: "MCI999") == nil)
    }
}
