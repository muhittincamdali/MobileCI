import MobileCIKit
import Testing
@testable import WorkflowCheck

/// The samples promise something in their titles; these tests keep the promise true when the
/// rules change.
@MainActor
struct SampleTests {
    @Test func firstWorkflowShowsTheMobileProblems() {
        let rules = Set(CheckModel.check(Sample.firstWorkflow.text).map(\.rule))
        #expect(rules.isSuperset(of: [.unpinnedAction, .floatingMacOSImage, .macOSJobWithoutTimeout,
                                      .macOSWorkflowWithoutConcurrency, .xcodeNotSelected,
                                      .defaultTokenPermissions, .pipeHidesBuildFailure]))
    }

    @Test func injectionSampleIsAnError() {
        let findings = CheckModel.check(Sample.injection.text)
        let injection = findings.first { $0.rule == .untrustedInputInScript }
        #expect(injection?.severity == .error)
        #expect(injection?.location.line == 9)
    }

    @Test func generatedWorkflowHasNoFindings() {
        #expect(CheckModel.check(Sample.generated.text).isEmpty)
    }

    @Test func choosingASampleReplacesTheTextAndFindings() {
        let model = CheckModel(sample: .generated)
        #expect(model.summary == "No findings")
        model.sample = .injection
        #expect(model.text == Sample.injection.text)
        #expect(model.summary.contains("1 error"))
    }

    @Test func editingTheTextChecksItAgain() {
        let model = CheckModel(sample: .generated)
        model.text = "name: broken\non: push\njobs: ["
        #expect(model.findings.map(\.rule) == [.invalidWorkflow])
    }
}

struct AppVersionTests {
    @Test func readsVersionAndBuild() {
        let info: [String: Any] = ["CFBundleShortVersionString": "2.4.0", "CFBundleVersion": "57"]
        #expect(AppVersion.label(info: info) == "Version 2.4.0 (57)")
    }

    @Test func missingKeysShowAQuestionMark() {
        #expect(AppVersion.label(info: nil) == "Version ? (?)")
        #expect(AppVersion.label(info: ["CFBundleVersion": 3]) == "Version ? (?)")
    }
}
