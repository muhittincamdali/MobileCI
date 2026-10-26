import MobileCIKit

/// The workflows the app starts with. Each one shows a different part of MobileCIKit.
enum Sample: String, CaseIterable, Identifiable {
    case firstWorkflow
    case injection
    case generated

    var id: String { rawValue }

    var title: String {
        switch self {
        case .firstWorkflow: return "A first iOS workflow"
        case .injection: return "Pull request title in a script"
        case .generated: return "Written by WorkflowGenerator"
        }
    }

    var text: String {
        switch self {
        case .firstWorkflow: return Self.firstWorkflowText
        case .injection: return Self.injectionText
        case .generated: return Self.generatedText
        }
    }

    /// What many first workflows look like: it works until the runner image changes, a test
    /// fails behind a pipe or a simulator hangs.
    static let firstWorkflowText = """
    name: iOS
    on: [push, pull_request]
    jobs:
      test:
        runs-on: macos-latest
        steps:
          - uses: actions/checkout@v4
          - name: Test
            run: |
              xcodebuild test -scheme App \\
                -destination 'platform=iOS Simulator,name=iPhone 17' | xcbeautify
    """

    static let injectionText = """
    name: Greet
    on: pull_request_target
    permissions:
      pull-requests: write
    jobs:
      greet:
        runs-on: ubuntu-24.04
        steps:
          - run: echo "Thanks for ${{ github.event.pull_request.title }}"
    """

    /// The workflow `mobileci init` writes for this app.
    static var generatedText: String {
        let project = DetectedProject(directory: ".", kind: .xcode(XcodeProject(
            projectFile: "WorkflowCheck.xcodeproj",
            workspaceFile: nil,
            schemes: [XcodeScheme(name: "WorkflowCheck", hasTests: true)],
            platform: .iOS,
            usesCocoaPods: false,
            usesBundler: false,
            usesSwiftPackages: false
        )))
        do {
            return try WorkflowGenerator().workflow(for: project).contents
        } catch {
            return "# \(error)"
        }
    }
}
