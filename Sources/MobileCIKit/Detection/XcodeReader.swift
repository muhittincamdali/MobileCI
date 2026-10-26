import Foundation

/// Reads what CI needs from an `.xcodeproj` without running Xcode: shared schemes, the platform
/// from `SDKROOT`, CocoaPods and Swift package use.
enum XcodeReader {
    static func project(_ projectFile: String, in folder: URL, entries: [ProjectDetector.Entry],
                        note: (Severity, String) -> Void) -> XcodeProject {
        let names = Set(entries.map(\.name))
        let projectURL = folder.appendingPathComponent(projectFile, isDirectory: true)
        let projectName = String(projectFile.dropLast(".xcodeproj".count))
        let usesCocoaPods = names.contains("Podfile")
        let workspaces = entries.filter { $0.isFolder && $0.name.hasSuffix(".xcworkspace") }.map(\.name)
        let workspace = workspaces.first { $0 == projectName + ".xcworkspace" } ?? workspaces.first
            ?? (usesCocoaPods ? projectName + ".xcworkspace" : nil)

        var schemes = sharedSchemes(in: projectURL)
        if let workspace {
            let fromWorkspace = sharedSchemes(in: folder.appendingPathComponent(workspace, isDirectory: true))
            schemes += fromWorkspace.filter { scheme in !schemes.contains { $0.name == scheme.name } }
        }
        if schemes.isEmpty {
            note(.warning, "\(projectFile.sanitizedForTerminal) has no shared scheme, so xcodebuild on CI cannot find one. In Xcode choose Product › Scheme › Manage Schemes…, tick Shared for the app's scheme and commit the .xcscheme file.")
        }
        let projectText = (try? TextFile.read(projectURL.appendingPathComponent("project.pbxproj"), limit: TextFile.projectFileLimit)) ?? ""
        let resolvedFile = "project.xcworkspace/xcshareddata/swiftpm/Package.resolved"
        let usesSwiftPackages = projectText.contains("XCRemoteSwiftPackageReference")
            || FileManager.default.fileExists(atPath: projectURL.appendingPathComponent(resolvedFile).path)

        return XcodeProject(
            projectFile: projectFile,
            workspaceFile: workspace,
            schemes: schemes.sorted { $0.name < $1.name },
            platform: platform(fromProjectText: projectText),
            usesCocoaPods: usesCocoaPods,
            usesBundler: usesCocoaPods && names.contains("Gemfile"),
            usesSwiftPackages: usesSwiftPackages
        )
    }

    /// Scheme files read per bundle; a project has a handful.
    static let maximumSchemeFiles = 200

    /// `xcshareddata/xcschemes/*.xcscheme` inside a project or workspace bundle.
    static func sharedSchemes(in bundle: URL) -> [XcodeScheme] {
        let folder = bundle.appendingPathComponent("xcshareddata/xcschemes", isDirectory: true)
        let files = DirectoryListing.entries(of: folder, limit: maximumSchemeFiles).urls
        return files.filter { $0.pathExtension == "xcscheme" }.map { file in
            let text = (try? TextFile.read(file)) ?? ""
            let hasTests = text.contains("<TestableReference") || text.contains("<TestPlanReference")
            return XcodeScheme(name: file.deletingPathExtension().lastPathComponent, hasTests: hasTests)
        }
    }

    /// macOS when every `SDKROOT` in the project is `macosx`; iOS otherwise (including
    /// multiplatform targets with `SDKROOT = auto`).
    static func platform(fromProjectText text: String) -> ApplePlatform {
        var roots = Set<String>()
        for line in text.split(separator: "\n") {
            let trimmed = line.trimmingCharacters(in: .whitespaces)
            guard trimmed.hasPrefix("SDKROOT = ") else { continue }
            let value = trimmed.dropFirst("SDKROOT = ".count).trimmingCharacters(in: CharacterSet(charactersIn: "\";"))
            roots.insert(value)
        }
        return !roots.isEmpty && roots.allSatisfy({ $0 == "macosx" }) ? .macOS : .iOS
    }
}
