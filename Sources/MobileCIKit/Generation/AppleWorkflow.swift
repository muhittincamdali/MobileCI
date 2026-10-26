/// Workflows for Xcode projects and Swift packages.
enum AppleWorkflow {
    static func write(_ project: XcodeProject, directory: String, fileName: String,
                      options: GeneratorOptions, into writer: inout WorkflowWriter) throws(GeneratorError) {
        let scheme = try chooseScheme(in: project, options: options)
        try Validation.check("project file", project.projectFile, allowed: Validation.name)
        if let workspace = project.workspaceFile {
            try Validation.check("workspace file", workspace, allowed: Validation.name)
        }
        let kind = project.platform == .macOS ? "macOS app" : "iOS app"
        let action = scheme.hasTests ? "test" : "build"
        let destination = project.platform == .macOS
            ? "platform=macOS"
            : "platform=iOS Simulator,name=\(options.simulator),OS=latest"

        writer.header(kind: kind, directory: directory, fileName: fileName, options: options)
        writer.job(action == "test" ? "build-and-test" : "build",
                   name: action == "test" ? "Build and test" : "Build",
                   runner: options.macOSRunner, timeout: 45)
        writer.developerDirectory(options)
        writer.workingDirectory(directory)
        writer.steps()
        writer.checkout()
        writer.step("Show the toolchain", run: "xcodebuild -version")
        if project.usesSwiftPackages {
            writer.uses("Cache Swift packages", .cache, with: [
                ("path", WorkflowWriter.quoted(directory.joinedPath("SourcePackages"))),
                ("key", "spm-${{ runner.os }}-${{ hashFiles('\(directory.joinedPath("**/Package.resolved"))') }}"),
                ("restore-keys", "spm-${{ runner.os }}-")
            ])
        }
        if project.usesCocoaPods {
            writeCocoaPods(bundler: project.usesBundler, directory: directory, into: &writer)
        }

        var command = ["set -o pipefail", "xcodebuild \(action) \\"]
        var env = [("SCHEME", scheme.name), ("DESTINATION", destination)]
        if let workspace = project.workspaceFile {
            env.insert(("WORKSPACE", workspace), at: 0)
            command.append("  -workspace \"$WORKSPACE\" \\")
        } else {
            env.insert(("PROJECT", project.projectFile), at: 0)
            command.append("  -project \"$PROJECT\" \\")
        }
        command += ["  -scheme \"$SCHEME\" \\", "  -destination \"$DESTINATION\" \\"]
        if project.usesSwiftPackages { command.append("  -clonedSourcePackagesDirPath SourcePackages \\") }
        command += ["  -resultBundlePath TestResults.xcresult \\", "  CODE_SIGNING_ALLOWED=NO \\", "  -quiet"]
        writer.step(action == "test" ? "Build and test" : "Build", run: command.joined(separator: "\n"), env: env)

        writer.uses("Upload the result bundle", .uploadArtifact, with: [
            ("name", "TestResults"),
            ("path", WorkflowWriter.quoted(directory.joinedPath("TestResults.xcresult"))),
            ("if-no-files-found", "ignore")
        ], condition: "failure()")
    }

    static func chooseScheme(in project: XcodeProject, options: GeneratorOptions) throws(GeneratorError) -> XcodeScheme {
        if let requested = options.scheme {
            guard let scheme = project.schemes.first(where: { $0.name == requested }) else {
                throw .unknownScheme(requested, available: project.schemes.map(\.name))
            }
            return scheme
        }
        guard let scheme = project.defaultScheme else { throw .noScheme(project: project.projectFile) }
        try Validation.check("scheme", scheme.name, allowed: Validation.name)
        return scheme
    }

    private static func writeCocoaPods(bundler: Bool, directory: String, into writer: inout WorkflowWriter) {
        writer.uses("Cache CocoaPods", .cache, with: [
            ("path", WorkflowWriter.quoted(directory.joinedPath("Pods"))),
            ("key", "pods-${{ runner.os }}-${{ hashFiles('\(directory.joinedPath("Podfile.lock"))') }}")
        ])
        let command = bundler ? "bundle install\nbundle exec pod install" : "pod install"
        writer.step("Install CocoaPods dependencies", run: command)
    }

    static func write(_ package: SwiftPackage, directory: String, fileName: String,
                      options: GeneratorOptions, into writer: inout WorkflowWriter) {
        writer.header(kind: "Swift package", directory: directory, fileName: fileName, options: options)
        writer.job(package.hasTests ? "build-and-test" : "build",
                   name: package.hasTests ? "Build and test" : "Build",
                   runner: options.macOSRunner, timeout: 30)
        writer.developerDirectory(options)
        writer.workingDirectory(directory)
        writer.steps()
        writer.checkout()
        writer.step("Show the toolchain", run: "swift --version")
        let manifests = ["Package.swift", "Package.resolved"].map { "'\(directory.joinedPath($0))'" }.joined(separator: ", ")
        writer.uses("Cache the build folder", .cache, with: [
            ("path", WorkflowWriter.quoted(directory.joinedPath(".build"))),
            ("key", "spm-build-${{ runner.os }}-${{ hashFiles(\(manifests)) }}"),
            ("restore-keys", "spm-build-${{ runner.os }}-")
        ])
        writer.step("Build", run: package.hasTests ? "swift build --build-tests" : "swift build")
        if package.hasTests {
            writer.step("Test", run: "swift test --skip-build --parallel")
        }
    }
}
