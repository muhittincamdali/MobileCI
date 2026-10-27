import Foundation

extension Rules {
    // MARK: MCI005

    /// Commands that use the selected Xcode (`xcode-select -p` or `DEVELOPER_DIR`).
    static let xcodeCommands = ["xcodebuild", "xcrun", "fastlane", "flutter build ios", "flutter build ipa",
                                "swift build", "swift test", "pod install", "agvtool"]

    static func checkXcodeSelection(_ context: inout RuleContext) {
        let workflow = context.workflow
        let workflowSelects = selectsXcode(env: workflow.env)
        for job in workflow.jobs where job.reusableWorkflow == nil && job.runsOnMacOS {
            guard !workflowSelects, !selectsXcode(env: job.env) else { continue }
            let steps = job.steps
            let selects = steps.contains { step in
                selectsXcode(env: step.env) || (step.actionName?.hasSuffix("/setup-xcode") ?? false)
                    || (step.run?.string.map(selectsXcode(script:)) ?? false)
            }
            guard !selects, let first = steps.first(where: { step in
                guard let script = step.run?.string else { return false }
                return xcodeCommands.contains { script.contains($0) }
            }), let run = first.run else { continue }
            context.report(.xcodeNotSelected, at: run.location,
                           "Job \(jobName(job)) builds with the runner image's default Xcode, which changes when the image is updated; select a version.")
        }
    }

    private static func selectsXcode(env: YAMLValue?) -> Bool {
        env?["DEVELOPER_DIR"] != nil
    }

    private static func selectsXcode(script: String) -> Bool {
        script.contains("xcode-select -s") || script.contains("xcode-select --switch")
            || script.contains("xcodes select") || script.contains("DEVELOPER_DIR=")
    }

    // MARK: MCI012, MCI013, MCI014

    static func checkSetupActions(_ context: inout RuleContext) {
        for job in context.workflow.jobs {
            for step in job.steps {
                guard let action = step.actionName, let uses = step.uses else { continue }
                switch action {
                case "actions/checkout":
                    if step.input("persist-credentials")?.lowercased() != "false" {
                        context.report(.checkoutPersistsCredentials, at: uses.location,
                                       "actions/checkout keeps GITHUB_TOKEN in .git/config, readable by every later step; set `persist-credentials: false` unless a step pushes.")
                    }
                case "subosito/flutter-action":
                    if step.input("flutter-version") == nil, step.input("flutter-version-file") == nil {
                        context.report(.flutterVersionNotPinned, at: uses.location,
                                       "subosito/flutter-action installs the newest Flutter of the channel on every run; set `flutter-version` or `flutter-version-file`.")
                    }
                case "actions/setup-node":
                    if step.input("node-version") == nil, step.input("node-version-file") == nil {
                        context.report(.nodeVersionNotPinned, at: uses.location,
                                       "actions/setup-node without `node-version` or `node-version-file` keeps the runner's preinstalled Node, which changes with the image.")
                    }
                default:
                    break
                }
            }
        }
    }
}
