import ArgumentParser
import Foundation
import MobileCIKit

struct DetectCommand: ParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "detect",
        abstract: "List the projects CI would build, with the details a workflow needs."
    )

    @Argument(help: "The repository folder.")
    var path: String = "."

    @Option(help: "Output format: text or json.")
    var format: OutputFormat = .text

    func run() throws {
        let root = CommandLinePath.url(path)
        let report = ProjectDetector().detect(in: root)
        switch format {
        case .text:
            print(DetectionText.render(report), terminator: "")
        case .json:
            print(DetectionJSON.render(report), terminator: "")
        }
        if report.projects.isEmpty { throw ExitCode(1) }
    }
}

enum OutputFormat: String, ExpressibleByArgument, CaseIterable {
    case text
    case json
}

enum DetectionText {
    static func render(_ report: DetectionReport) -> String {
        guard !report.projects.isEmpty else {
            return "No Xcode project, Swift package, Flutter or React Native project found.\n"
                + notes(report.notes)
        }
        var lines: [String] = []
        for project in report.projects {
            lines.append("\(project.kindName) in \(project.directory.sanitizedForTerminal)")
            lines += details(of: project).map { "  " + $0.sanitizedForTerminal }
            lines.append("  workflow: .github/workflows/\(WorkflowGenerator.fileName(for: project))")
        }
        return lines.joined(separator: "\n") + "\n" + notes(report.notes)
    }

    private static func details(of project: DetectedProject) -> [String] {
        switch project.kind {
        case .xcode(let xcode):
            return xcodeDetails(xcode)
        case .swiftPackage(let package):
            return ["package: \(package.name ?? "(name not read)")", "tests: \(package.hasTests ? "yes" : "no")"]
        case .flutter(let flutter):
            let version = flutter.pinnedFlutterVersion.map { "\($0) (pubspec.yaml)" }
                ?? (flutter.hasFVMConfig ? "from .fvmrc" : "not pinned; the workflow uses \(GeneratorOptions().flutterVersion)")
            return ["package: \(flutter.name ?? "(no name)")",
                    "platforms: \(flutter.platforms.sorted().joined(separator: ", ").ifEmpty("none (package)"))",
                    "Flutter: \(version)",
                    "tests: \(flutter.hasTests ? "yes" : "no")"]
        case .reactNative(let app):
            var lines = ["package: \(app.name ?? "(no name)")",
                         "package manager: \(app.packageManager.rawValue)",
                         "Node.js: \(app.nodeVersionFile ?? "not pinned; the workflow uses \(GeneratorOptions().nodeVersion)")",
                         "scripts run: \(ReactNativeScripts.listed(app.scripts))",
                         "android: \(app.hasAndroid ? "yes" : "no")"]
            if let iOS = app.iOS { lines += xcodeDetails(iOS).map { "ios/ " + $0 } } else { lines.append("ios: no") }
            return lines
        }
    }

    private static func xcodeDetails(_ xcode: XcodeProject) -> [String] {
        let schemes = xcode.schemes.map { $0.name + ($0.hasTests ? " (tests)" : "") }.joined(separator: ", ")
        var lines = ["project: \(xcode.projectFile)"]
        if let workspace = xcode.workspaceFile { lines.append("workspace: \(workspace)") }
        lines.append("shared schemes: \(schemes.ifEmpty("none"))")
        if let scheme = xcode.defaultScheme { lines.append("workflow scheme: \(scheme.name)") }
        lines.append("platform: \(xcode.platform.rawValue)")
        if xcode.usesCocoaPods { lines.append("CocoaPods: yes\(xcode.usesBundler ? " (through Bundler)" : "")") }
        if xcode.usesSwiftPackages { lines.append("Swift packages: yes") }
        return lines
    }

    static func notes(_ notes: [DetectionNote]) -> String {
        notes.map { "\($0.severity.rawValue): \($0.directory.sanitizedForTerminal): \($0.message.sanitizedForTerminal)\n" }.joined()
    }
}

enum ReactNativeScripts {
    static func listed(_ scripts: Set<String>) -> String {
        let used = ["lint", "typecheck", "type-check", "tsc", "test"].filter(scripts.contains)
        return used.isEmpty ? "none (add lint or test scripts to package.json)" : used.joined(separator: ", ")
    }
}

extension String {
    func ifEmpty(_ replacement: String) -> String {
        isEmpty ? replacement : self
    }
}
