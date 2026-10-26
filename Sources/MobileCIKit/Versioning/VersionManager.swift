import Foundation

/// A change to apply to the version files of one project.
public enum VersionChange: Sendable, Equatable {
    /// Increment one part of the version; with `build`, also the build number.
    case bump(VersionPart, build: Bool)
    /// Set the version to a value; with `build`, also the build number.
    case set(MarketingVersion, build: BuildNumber?)
    /// Increment the build number only.
    case nextBuild
    /// Set the build number only.
    case setBuild(BuildNumber)
}

/// The new contents of the files a ``VersionChange`` touches.
public struct VersionPlan: Sendable, Equatable {
    public let version: MarketingVersion?
    public let build: BuildNumber?
    public let files: [VersionFile]
    let newTexts: [String]

    /// Writes every file. Each is written atomically (a temporary file renamed over it).
    public func apply() throws {
        for (file, text) in zip(files, newTexts) where text != file.text {
            try Data(text.utf8).write(to: file.url, options: .atomic)
        }
    }
}

/// Reads and changes the version of iOS, Flutter, React Native and Expo projects in every file
/// that holds it, so `MARKETING_VERSION`, `pubspec.yaml`, `app.json` and `build.gradle` stay in
/// step.
public struct VersionManager: Sendable {
    public init() {}

    /// The files holding a version for `project`, found under `root`.
    public func files(for project: DetectedProject, root: URL) -> [VersionFile] {
        let folder = project.directory == "." ? root : root.appendingPathComponent(project.directory, isDirectory: true)
        func file(_ relative: String, _ format: VersionFileFormat) -> VersionFile? {
            VersionFile(url: folder.appendingPathComponent(relative), path: project.directory.joinedPath(relative), format: format)
        }
        switch project.kind {
        case .xcode(let xcode):
            return [file(xcode.projectFile + "/project.pbxproj", .xcodeProject)].compactMap { $0 }
        case .flutter:
            return [file("pubspec.yaml", .pubspec)].compactMap { $0 }
        case .reactNative(let reactNative):
            var files = [file("package.json", .packageJSON), file("app.json", .expo)]
            if let iOS = reactNative.iOS { files.append(file("ios/" + iOS.projectFile + "/project.pbxproj", .xcodeProject)) }
            if reactNative.hasAndroid {
                files.append(file("android/app/build.gradle", .gradle) ?? file("android/app/build.gradle.kts", .gradle))
            }
            return files.compactMap { $0 }
        case .swiftPackage:
            return []
        }
    }

    /// The highest version and build number in `files`. Values that do not parse are skipped.
    public func current(in files: [VersionFile]) -> (version: MarketingVersion?, build: BuildNumber?) {
        let versions = files.flatMap(\.versions).compactMap { try? MarketingVersion($0) }
        let builds = files.flatMap(\.buildNumbers).compactMap { try? BuildNumber($0) }
        return (versions.max(), builds.max())
    }

    /// The new file contents for `change`. Nothing is written until ``VersionPlan/apply()``.
    public func plan(_ change: VersionChange, files: [VersionFile]) throws(VersionError) -> VersionPlan {
        guard !files.isEmpty else {
            throw .nothingToChange("No version fields found (Swift packages are versioned by git tags).")
        }
        let (currentVersion, currentBuild) = current(in: files)
        var version: MarketingVersion?
        var build: BuildNumber?
        switch change {
        case .bump(let part, let bumpBuild):
            guard let currentVersion else { throw .nothingToChange("No readable version to bump; use `version set`.") }
            version = try currentVersion.bumped(part)
            if bumpBuild { build = try nextBuild(after: currentBuild, in: files) }
        case .set(let newVersion, let newBuild):
            version = newVersion
            if let newBuild { build = try settable(newBuild) }
        case .nextBuild:
            build = try nextBuild(after: currentBuild, in: files)
        case .setBuild(let newBuild):
            build = try settable(newBuild)
        }
        let texts = files.map { $0.updatedText(version: version?.description, build: build?.description) }
        return VersionPlan(version: version, build: build, files: files, newTexts: texts)
    }

    private func settable(_ build: BuildNumber) throws(VersionError) -> BuildNumber {
        guard build.value >= BuildNumber.minimumToSet else {
            throw .buildNumberTooSmall(build.description, minimum: BuildNumber.minimumToSet)
        }
        return build
    }

    /// The build after `current`. With no build field at all the first build is 1; build fields
    /// that exist but none of which is digits only (`CURRENT_PROJECT_VERSION = 1.2.3`) are
    /// refused, since counting from 1 would overwrite them with a lower build.
    private func nextBuild(after current: BuildNumber?, in files: [VersionFile]) throws(VersionError) -> BuildNumber {
        if let current { return try current.incremented() }
        if let unreadable = files.flatMap(\.buildNumbers).first {
            throw .unreadableBuildNumber(unreadable)
        }
        return try BuildNumber(value: 1)
    }
}
