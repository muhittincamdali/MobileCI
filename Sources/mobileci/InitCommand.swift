import ArgumentParser
import Foundation
import MobileCIKit

struct InitCommand: ParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "init",
        abstract: "Write a GitHub Actions workflow for each project in the repository.",
        discussion: """
        Workflows go to <path>/.github/workflows/. An existing file is left alone unless you pass \
        --force. With --stdout nothing is written.
        """
    )

    @Argument(help: "The repository root.")
    var path: String = "."

    @Option(name: .customLong("project"), help: "Only the project in this folder (relative to the root, as `detect` prints it).")
    var projectDirectory: String?

    @Option(name: .customLong("file"), help: "Workflow file name, such as ci.yml (only with --project).")
    var fileName: String?

    @Option(help: "Build this shared scheme instead of the one MobileCI picks.")
    var scheme: String?

    @Option(help: "The branch whose pushes run the workflow.")
    var branch: String?

    @Option(help: "Xcode version for macOS jobs (/Applications/Xcode_<version>.app on the runner).")
    var xcode: String = GeneratorOptions().xcodeVersion

    @Option(help: "Simulator device name for xcodebuild test.")
    var simulator: String = GeneratorOptions().simulator

    @Option(name: .customLong("macos-runner"), help: "Runner label for macOS jobs.")
    var macOSRunner: String = GeneratorOptions().macOSRunner

    @Option(name: .customLong("linux-runner"), help: "Runner label for Linux jobs.")
    var linuxRunner: String = GeneratorOptions().linuxRunner

    @Option(help: "Node.js version when the project has no .nvmrc or .node-version.")
    var node: String = GeneratorOptions().nodeVersion

    @Option(help: "Java version for Android builds.")
    var java: String = GeneratorOptions().javaVersion

    @Option(help: "Flutter version when pubspec.yaml does not pin one exactly.")
    var flutter: String = GeneratorOptions().flutterVersion

    @Flag(help: "Print the workflows instead of writing them.")
    var stdout = false

    @Flag(help: "Overwrite workflow files that already exist.")
    var force = false

    func validate() throws {
        if fileName != nil, projectDirectory == nil {
            throw ValidationError("--file needs --project, because each project gets its own file.")
        }
    }

    func run() throws {
        let root = CommandLinePath.url(path)
        let report = ProjectDetector().detect(in: root)
        var projects = report.projects
        if let projectDirectory {
            let wanted = projectDirectory.trimmingCharacters(in: CharacterSet(charactersIn: "/"))
            projects = projects.filter { $0.directory == (wanted.isEmpty ? "." : wanted) }
            guard !projects.isEmpty else {
                StandardError.write("No project in \(projectDirectory.sanitizedForTerminal); `mobileci detect` lists the folders.")
                throw ExitCode(1)
            }
        }
        guard !projects.isEmpty else {
            StandardError.write("No Xcode project, Swift package, Flutter or React Native project found in \(CommandLinePath.display(root).sanitizedForTerminal).")
            throw ExitCode(1)
        }
        let notes = DetectionText.notes(report.notes.filter { note in projects.contains { $0.directory == note.directory } })
        if !notes.isEmpty { StandardError.write(notes) }

        let generator = WorkflowGenerator(options: options(root: root))
        var failed = false
        for project in projects {
            do {
                let workflow = try generator.workflow(for: project, fileName: fileName)
                if stdout {
                    // A file marker only separates several workflows; one prints as a plain file.
                    if projects.count > 1 { print("# --- .github/workflows/\(workflow.fileName)") }
                    print(workflow.contents, terminator: "")
                    continue
                }
                try write(workflow, root: root)
            } catch let error as GeneratorError {
                StandardError.write("error: \(project.directory.sanitizedForTerminal): \(error.description)")
                failed = true
            }
        }
        if failed { throw ExitCode(1) }
    }

    private func options(root: URL) -> GeneratorOptions {
        var options = GeneratorOptions()
        options.branch = branch ?? DefaultBranch.read(in: root) ?? options.branch
        options.xcodeVersion = xcode
        options.simulator = simulator
        options.macOSRunner = macOSRunner
        options.linuxRunner = linuxRunner
        options.nodeVersion = node
        options.javaVersion = java
        options.flutterVersion = flutter
        options.scheme = scheme
        return options
    }

    private func write(_ workflow: GeneratedWorkflow, root: URL) throws {
        let folder = root.appendingPathComponent(".github/workflows", isDirectory: true)
        let file = folder.appendingPathComponent(workflow.fileName)
        if FileManager.default.fileExists(atPath: file.path), !force {
            StandardError.write("skipped: \(CommandLinePath.display(file).sanitizedForTerminal) exists (pass --force to overwrite it)")
            return
        }
        try FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true)
        try Data(workflow.contents.utf8).write(to: file, options: .atomic)
        print("wrote \(CommandLinePath.display(file).sanitizedForTerminal) (\(workflow.project.kindName) in \(workflow.project.directory.sanitizedForTerminal))")
    }
}

/// The default branch from `.git/refs/remotes/origin/HEAD` (written by `git clone`).
enum DefaultBranch {
    static func read(in root: URL) -> String? {
        let head = root.appendingPathComponent(".git/refs/remotes/origin/HEAD")
        guard let text = try? TextFile.read(head, limit: 4096) else { return nil }
        let prefix = "ref: refs/remotes/origin/"
        let line = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard line.hasPrefix(prefix) else { return nil }
        let branch = String(line.dropFirst(prefix.count))
        return branch.isEmpty ? nil : branch
    }
}
