import ArgumentParser
import Foundation
import MobileCIKit

extension VersionPart: ExpressibleByArgument {}

struct VersionOptions: ParsableArguments {
    @Option(name: .customLong("path"), help: "The repository root.")
    var path: String = "."

    @Option(name: .customLong("project"), help: "The project folder, as `mobileci detect` prints it, when the repository has several.")
    var projectDirectory: String?

    @Flag(name: .customLong("dry-run"), help: "Show the new values without writing any file.")
    var dryRun = false

    /// The one project to version, with its files.
    func load() throws -> (project: DetectedProject, files: [VersionFile], root: URL) {
        let root = CommandLinePath.url(path)
        var projects = ProjectDetector().detect(in: root).projects.filter {
            if case .swiftPackage = $0.kind { return false }
            return true
        }
        if let projectDirectory {
            let wanted = projectDirectory.trimmingCharacters(in: CharacterSet(charactersIn: "/"))
            projects = projects.filter { $0.directory == (wanted.isEmpty ? "." : wanted) }
        }
        guard projects.count == 1, let project = projects.first else {
            let list = projects.map { "\($0.kindName) in \($0.directory)".sanitizedForTerminal }.joined(separator: "; ")
            StandardError.write(projects.isEmpty
                ? "No app project found (Swift packages are versioned by git tags)."
                : "Several projects found (\(list)); choose one with --project.")
            throw ExitCode(1)
        }
        return (project, VersionManager().files(for: project, root: root), root)
    }

    func apply(_ change: VersionChange) throws {
        let (project, files, _) = try load()
        let plan: VersionPlan
        do {
            plan = try VersionManager().plan(change, files: files)
        } catch {
            StandardError.write("error: \(error.description)")
            throw ExitCode(1)
        }
        for file in plan.files {
            print("\(dryRun ? "would update" : "updated") \(file.path.sanitizedForTerminal)")
        }
        if let version = plan.version { print("version: \(version)") }
        if let build = plan.build { print("build: \(build)") }
        if !dryRun { try plan.apply() }
        _ = project
    }
}

struct VersionCommand: ParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "version",
        abstract: "Show or change the app version and build number in every file that holds them.",
        discussion: """
        Files: Xcode project.pbxproj (MARKETING_VERSION, CURRENT_PROJECT_VERSION), pubspec.yaml, \
        package.json, Expo app.json and android/app/build.gradle(.kts). A bump starts from the \
        highest value found and writes the result into every file.
        """,
        subcommands: [Show.self, Bump.self, Set.self, Build.self],
        defaultSubcommand: Show.self
    )

    struct Show: ParsableCommand {
        static let configuration = CommandConfiguration(abstract: "List each file's version and build number.")

        @OptionGroup var options: VersionOptions

        func run() throws {
            let (project, files, _) = try options.load()
            print("\(project.kindName) in \(project.directory.sanitizedForTerminal)")
            guard !files.isEmpty else {
                print("  no version fields found")
                return
            }
            for file in files {
                let versions = Array(Swift.Set(file.versions)).sorted().joined(separator: ", ")
                let builds = Array(Swift.Set(file.buildNumbers)).sorted().joined(separator: ", ")
                print("  \(file.path): version \(versions.ifEmpty("-")), build \(builds.ifEmpty("-"))".sanitizedForTerminal)
            }
            let current = VersionManager().current(in: files)
            print("  current: version \(current.version?.description ?? "-"), build \(current.build?.description ?? "-")")
        }
    }

    struct Bump: ParsableCommand {
        static let configuration = CommandConfiguration(abstract: "Increment the major, minor or patch part.")

        @Argument(help: "major, minor or patch.")
        var part: VersionPart

        @Flag(help: "Also increment the build number.")
        var build = false

        @OptionGroup var options: VersionOptions

        func run() throws {
            try options.apply(.bump(part, build: build))
        }
    }

    struct Set: ParsableCommand {
        static let configuration = CommandConfiguration(abstract: "Set the version, and optionally the build number.")

        @Argument(help: "The new version, such as 2.4.0.")
        var version: String

        @Option(help: "The new build number.")
        var build: String?

        @OptionGroup var options: VersionOptions

        func run() throws {
            do {
                let marketing = try MarketingVersion(version)
                let buildNumber = try build.map { value throws(VersionError) in try BuildNumber(value) }
                try options.apply(.set(marketing, build: buildNumber))
            } catch let error as VersionError {
                throw ValidationError(error.description)
            }
        }
    }

    struct Build: ParsableCommand {
        static let configuration = CommandConfiguration(abstract: "Increment the build number, or set it with --set.")

        @Option(name: .customLong("set"), help: ArgumentHelp("The new build number.", valueName: "number"))
        var value: String?

        @OptionGroup var options: VersionOptions

        func run() throws {
            do {
                let change: VersionChange = try value.map { text throws(VersionError) in .setBuild(try BuildNumber(text)) } ?? .nextBuild
                try options.apply(change)
            } catch let error as VersionError {
                throw ValidationError(error.description)
            }
        }
    }
}
