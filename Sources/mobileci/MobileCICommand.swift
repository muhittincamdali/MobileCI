import ArgumentParser
import Foundation
import MobileCIKit

@main
struct MobileCICommand: ParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "mobileci",
        abstract: "Write, check and version the CI of iOS, Flutter and React Native apps.",
        discussion: """
        Start in the root of your repository:

          mobileci detect          what CI will see (projects, schemes, versions of tools)
          mobileci init            write .github/workflows/<kind>.yml for each project
          mobileci lint            check every workflow in .github/workflows
          mobileci version bump patch --build

        Documentation: \(MobileCIInfo.documentationURL)
        """,
        version: MobileCIInfo.version,
        subcommands: [DetectCommand.self, InitCommand.self, LintCommand.self, RulesCommand.self, VersionCommand.self]
    )
}

/// Paths given on the command line, resolved against the current directory.
enum CommandLinePath {
    static var currentDirectory: URL {
        URL(fileURLWithPath: FileManager.default.currentDirectoryPath, isDirectory: true)
    }

    static func url(_ path: String) -> URL {
        URL(fileURLWithPath: path, relativeTo: currentDirectory).standardizedFileURL
    }

    /// `path` relative to the current directory when it is inside it.
    static func display(_ url: URL) -> String {
        let base = currentDirectory.standardizedFileURL.path
        let path = url.standardizedFileURL.path
        if path == base { return "." }
        if path.hasPrefix(base + "/") { return String(path.dropFirst(base.count + 1)) }
        return path
    }
}

/// Prints to standard error.
enum StandardError {
    static func write(_ text: String) {
        FileHandle.standardError.write(Data((text.hasSuffix("\n") ? text : text + "\n").utf8))
    }
}
