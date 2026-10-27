import Foundation

/// A workflow file ``WorkflowGenerator`` wrote for one project.
public struct GeneratedWorkflow: Sendable, Equatable {
    /// The file name under `.github/workflows/`, such as `ios.yml`.
    public let fileName: String
    public let contents: String
    public let project: DetectedProject
}

/// Writes a GitHub Actions workflow for a ``DetectedProject``.
///
/// Every generated workflow:
/// - pins each action to the commit of its release (``PinnedAction``),
/// - grants `contents: read` only and does not keep the token in `.git/config`,
/// - cancels superseded pull request runs and sets a timeout on every job,
/// - selects the Xcode version on macOS jobs and pins Node.js, Java and Flutter,
/// - passes project values (scheme, workspace) through `env:` to the scripts,
/// so it passes `mobileci lint` without findings.
public struct WorkflowGenerator: Sendable {
    public let options: GeneratorOptions

    public init(options: GeneratorOptions = GeneratorOptions()) {
        self.options = options
    }

    /// Writes the workflow for one project.
    ///
    /// - Parameters:
    ///   - project: A project from ``ProjectDetector``, or one described by hand.
    ///   - fileName: The file name under `.github/workflows/`; ``fileName(for:)`` when `nil`.
    ///     It must end in `.yml` or `.yaml` and use only letters, digits, `.`, `_` and `-`.
    public func workflow(for project: DetectedProject, fileName: String? = nil) throws(GeneratorError) -> GeneratedWorkflow {
        let options = try options.validated()
        try Validation.checkFolder("project folder", project.directory)
        if let fileName {
            try Validation.check("file name", fileName, allowed: Validation.label)
            guard fileName.hasSuffix(".yml") || fileName.hasSuffix(".yaml"), !fileName.hasPrefix(".") else {
                throw .invalidValue(field: "file name", reason: "it must end in .yml or .yaml")
            }
        }
        let fileName = fileName ?? Self.fileName(for: project)
        var writer = WorkflowWriter()
        switch project.kind {
        case .xcode(let xcode):
            try AppleWorkflow.write(xcode, directory: project.directory, fileName: fileName, options: options, into: &writer)
        case .swiftPackage(let package):
            AppleWorkflow.write(package, directory: project.directory, fileName: fileName, options: options, into: &writer)
        case .flutter(let flutter):
            FlutterWorkflow.write(flutter, directory: project.directory, fileName: fileName, options: options, into: &writer)
        case .reactNative(let reactNative):
            try ReactNativeWorkflow.write(reactNative, directory: project.directory, fileName: fileName,
                                          options: options, into: &writer)
        }
        return GeneratedWorkflow(fileName: fileName, contents: writer.text, project: project)
    }

    /// `ios.yml` for a project at the root; `ios-examples-sampleapp.yml` for one in
    /// `Examples/SampleApp`, so several projects in one repository get separate files.
    public static func fileName(for project: DetectedProject) -> String {
        let base: String
        switch project.kind {
        case .xcode(let xcode): base = xcode.platform == .macOS ? "macos" : "ios"
        case .swiftPackage: base = "swift-package"
        case .flutter: base = "flutter"
        case .reactNative(let reactNative): base = reactNative.isExpo ? "expo" : "react-native"
        }
        guard project.directory != "." else { return base + ".yml" }
        var slug = ""
        for scalar in project.directory.lowercased().unicodeScalars {
            let isPlain = ("a"..."z").contains(scalar) || ("0"..."9").contains(scalar)
            if isPlain {
                slug.unicodeScalars.append(scalar)
            } else if !slug.isEmpty, slug.last != "-" {
                slug.append("-")
            }
        }
        slug = String(slug.prefix(60))
        while slug.hasSuffix("-") { slug.removeLast() }
        return slug.isEmpty ? base + ".yml" : "\(base)-\(slug).yml"
    }
}
