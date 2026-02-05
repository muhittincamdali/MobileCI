// VersionManager.swift
// MobileCIKit
//
// Comprehensive version and build number management for mobile applications.
// Supports semantic versioning, auto-increment, and platform-specific formats.

import Foundation

// MARK: - Semantic Version

/// Represents a semantic version (MAJOR.MINOR.PATCH)
public struct SemanticVersion: Comparable, CustomStringConvertible, Codable, Sendable {
    public let major: Int
    public let minor: Int
    public let patch: Int
    public let prerelease: String?
    public let build: String?
    
    public init(
        major: Int,
        minor: Int,
        patch: Int,
        prerelease: String? = nil,
        build: String? = nil
    ) {
        self.major = major
        self.minor = minor
        self.patch = patch
        self.prerelease = prerelease
        self.build = build
    }
    
    /// Parse version from string
    public init?(string: String) {
        let pattern = #"^(\d+)\.(\d+)\.(\d+)(?:-([0-9A-Za-z-.]+))?(?:\+([0-9A-Za-z-.]+))?$"#
        
        guard let regex = try? NSRegularExpression(pattern: pattern),
              let match = regex.firstMatch(in: string, range: NSRange(string.startIndex..., in: string)) else {
            return nil
        }
        
        func getString(_ index: Int) -> String? {
            guard let range = Range(match.range(at: index), in: string) else { return nil }
            return String(string[range])
        }
        
        guard let majorStr = getString(1), let major = Int(majorStr),
              let minorStr = getString(2), let minor = Int(minorStr),
              let patchStr = getString(3), let patch = Int(patchStr) else {
            return nil
        }
        
        self.major = major
        self.minor = minor
        self.patch = patch
        self.prerelease = getString(4)
        self.build = getString(5)
    }
    
    // MARK: - Version Bumping
    
    /// Bump major version (X.0.0)
    public func bumpMajor() -> SemanticVersion {
        return SemanticVersion(major: major + 1, minor: 0, patch: 0)
    }
    
    /// Bump minor version (x.X.0)
    public func bumpMinor() -> SemanticVersion {
        return SemanticVersion(major: major, minor: minor + 1, patch: 0)
    }
    
    /// Bump patch version (x.x.X)
    public func bumpPatch() -> SemanticVersion {
        return SemanticVersion(major: major, minor: minor, patch: patch + 1)
    }
    
    /// Set prerelease identifier
    public func withPrerelease(_ prerelease: String?) -> SemanticVersion {
        return SemanticVersion(major: major, minor: minor, patch: patch, prerelease: prerelease, build: build)
    }
    
    /// Set build metadata
    public func withBuild(_ build: String?) -> SemanticVersion {
        return SemanticVersion(major: major, minor: minor, patch: patch, prerelease: prerelease, build: build)
    }
    
    // MARK: - String Representation
    
    public var description: String {
        var version = "\(major).\(minor).\(patch)"
        if let prerelease = prerelease {
            version += "-\(prerelease)"
        }
        if let build = build {
            version += "+\(build)"
        }
        return version
    }
    
    /// Short version (no prerelease or build)
    public var shortVersion: String {
        return "\(major).\(minor).\(patch)"
    }
    
    /// Marketing version for App Store
    public var marketingVersion: String {
        return "\(major).\(minor).\(patch)"
    }
    
    // MARK: - Comparable
    
    public static func < (lhs: SemanticVersion, rhs: SemanticVersion) -> Bool {
        if lhs.major != rhs.major { return lhs.major < rhs.major }
        if lhs.minor != rhs.minor { return lhs.minor < rhs.minor }
        if lhs.patch != rhs.patch { return lhs.patch < rhs.patch }
        
        // Prerelease versions have lower precedence
        if lhs.prerelease != nil && rhs.prerelease == nil { return true }
        if lhs.prerelease == nil && rhs.prerelease != nil { return false }
        if let lhsPre = lhs.prerelease, let rhsPre = rhs.prerelease {
            return lhsPre < rhsPre
        }
        
        return false
    }
}

// MARK: - Build Number

/// Represents a build number with various formats
public struct BuildNumber: Comparable, CustomStringConvertible, Sendable {
    public enum Format: String, CaseIterable, Sendable {
        case integer          // 123
        case dateTime         // 202401151430
        case dateBuild        // 2024.01.15.1
        case versionBuild     // 1.2.3.456
        case hash             // abc1234
    }
    
    public let value: Int
    public let format: Format
    
    public init(value: Int, format: Format = .integer) {
        self.value = value
        self.format = format
    }
    
    /// Create from current date/time
    public static func fromDateTime() -> BuildNumber {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyyMMddHHmm"
        let value = Int(formatter.string(from: Date())) ?? 0
        return BuildNumber(value: value, format: .dateTime)
    }
    
    /// Create from date with build index
    public static func fromDateBuild(buildIndex: Int = 1) -> BuildNumber {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyyMMdd"
        let dateValue = Int(formatter.string(from: Date())) ?? 0
        let value = dateValue * 100 + buildIndex
        return BuildNumber(value: value, format: .dateBuild)
    }
    
    /// Create incremented build number
    public func increment() -> BuildNumber {
        return BuildNumber(value: value + 1, format: format)
    }
    
    public var description: String {
        switch format {
        case .integer:
            return "\(value)"
        case .dateTime:
            return "\(value)"
        case .dateBuild:
            let date = value / 100
            let build = value % 100
            let year = date / 10000
            let month = (date % 10000) / 100
            let day = date % 100
            return "\(year).\(month).\(day).\(build)"
        case .versionBuild:
            return "\(value)"
        case .hash:
            return String(format: "%08x", value)
        }
    }
    
    public static func < (lhs: BuildNumber, rhs: BuildNumber) -> Bool {
        return lhs.value < rhs.value
    }
}

// MARK: - Version Manager

/// Manages version numbers for mobile projects
public final class VersionManager: @unchecked Sendable {
    public static let shared = VersionManager()
    
    private let fileManager = FileManager.default
    private let processRunner = ProcessRunner.shared
    private let logger = Logger.shared
    
    private init() {}
    
    // MARK: - iOS/Xcode Projects
    
    /// Get version from Info.plist
    public func getVersionFromInfoPlist(path: String) throws -> (version: String, build: String) {
        let result = try processRunner.run(
            "/usr/libexec/PlistBuddy -c 'Print CFBundleShortVersionString' '\(path)'"
        )
        let versionResult = try processRunner.run(
            "/usr/libexec/PlistBuddy -c 'Print CFBundleVersion' '\(path)'"
        )
        
        return (result.stdout.trimmingCharacters(in: .whitespacesAndNewlines),
                versionResult.stdout.trimmingCharacters(in: .whitespacesAndNewlines))
    }
    
    /// Set version in Info.plist
    public func setVersionInInfoPlist(
        path: String,
        version: String? = nil,
        build: String? = nil
    ) throws {
        if let version = version {
            _ = try processRunner.run(
                "/usr/libexec/PlistBuddy -c 'Set :CFBundleShortVersionString \(version)' '\(path)'"
            )
            logger.success("Set version to \(version) in \(path)")
        }
        
        if let build = build {
            _ = try processRunner.run(
                "/usr/libexec/PlistBuddy -c 'Set :CFBundleVersion \(build)' '\(path)'"
            )
            logger.success("Set build to \(build) in \(path)")
        }
    }
    
    /// Get version from Xcode project using agvtool
    public func getVersionFromXcodeProject(projectPath: String) throws -> (version: String, build: String) {
        let versionResult = try processRunner.run(
            "cd '\(projectPath)' && agvtool what-marketing-version -terse1"
        )
        let buildResult = try processRunner.run(
            "cd '\(projectPath)' && agvtool what-version -terse"
        )
        
        return (versionResult.stdout.trimmingCharacters(in: .whitespacesAndNewlines),
                buildResult.stdout.trimmingCharacters(in: .whitespacesAndNewlines))
    }
    
    /// Set version in Xcode project using agvtool
    public func setVersionInXcodeProject(
        projectPath: String,
        version: String? = nil,
        build: String? = nil
    ) throws {
        if let version = version {
            _ = try processRunner.run(
                "cd '\(projectPath)' && agvtool new-marketing-version '\(version)'"
            )
            logger.success("Set marketing version to \(version)")
        }
        
        if let build = build {
            _ = try processRunner.run(
                "cd '\(projectPath)' && agvtool new-version -all '\(build)'"
            )
            logger.success("Set build version to \(build)")
        }
    }
    
    // MARK: - Android Projects
    
    /// Get version from build.gradle
    public func getVersionFromGradle(buildGradlePath: String) throws -> (versionName: String, versionCode: Int) {
        let content = try String(contentsOfFile: buildGradlePath, encoding: .utf8)
        
        var versionName = "1.0.0"
        var versionCode = 1
        
        // Match versionName
        if let match = content.range(of: #"versionName\s*[=:]\s*["']([^"']+)["']"#, options: .regularExpression) {
            let value = content[match]
            if let quoteStart = value.firstIndex(of: "\"") ?? value.firstIndex(of: "'"),
               let quoteEnd = value.lastIndex(of: "\"") ?? value.lastIndex(of: "'") {
                versionName = String(value[value.index(after: quoteStart)..<quoteEnd])
            }
        }
        
        // Match versionCode
        if let match = content.range(of: #"versionCode\s*[=:]\s*(\d+)"#, options: .regularExpression) {
            let value = content[match]
            if let numberMatch = value.range(of: #"\d+"#, options: .regularExpression) {
                versionCode = Int(value[numberMatch]) ?? 1
            }
        }
        
        return (versionName, versionCode)
    }
    
    /// Set version in build.gradle
    public func setVersionInGradle(
        buildGradlePath: String,
        versionName: String? = nil,
        versionCode: Int? = nil
    ) throws {
        var content = try String(contentsOfFile: buildGradlePath, encoding: .utf8)
        
        if let versionName = versionName {
            // Replace versionName
            content = content.replacingOccurrences(
                of: #"(versionName\s*[=:]\s*)["'][^"']+["']"#,
                with: "$1\"\(versionName)\"",
                options: .regularExpression
            )
            logger.success("Set versionName to \(versionName)")
        }
        
        if let versionCode = versionCode {
            // Replace versionCode
            content = content.replacingOccurrences(
                of: #"(versionCode\s*[=:]\s*)\d+"#,
                with: "$1\(versionCode)",
                options: .regularExpression
            )
            logger.success("Set versionCode to \(versionCode)")
        }
        
        try content.write(toFile: buildGradlePath, atomically: true, encoding: .utf8)
    }
    
    // MARK: - Flutter Projects
    
    /// Get version from pubspec.yaml
    public func getVersionFromPubspec(path: String) throws -> (version: String, build: Int) {
        let content = try String(contentsOfFile: path, encoding: .utf8)
        
        // Match version: 1.0.0+1
        guard let match = content.range(of: #"version:\s*(\d+\.\d+\.\d+)(?:\+(\d+))?"#, options: .regularExpression) else {
            throw VersionError.versionNotFound
        }
        
        let value = String(content[match])
        let parts = value.replacingOccurrences(of: "version:", with: "")
            .trimmingCharacters(in: .whitespaces)
            .components(separatedBy: "+")
        
        let version = parts[0]
        let build = parts.count > 1 ? (Int(parts[1]) ?? 1) : 1
        
        return (version, build)
    }
    
    /// Set version in pubspec.yaml
    public func setVersionInPubspec(
        path: String,
        version: String? = nil,
        build: Int? = nil
    ) throws {
        var content = try String(contentsOfFile: path, encoding: .utf8)
        
        let current = try getVersionFromPubspec(path: path)
        let newVersion = version ?? current.version
        let newBuild = build ?? current.build
        
        content = content.replacingOccurrences(
            of: #"version:\s*\d+\.\d+\.\d+(?:\+\d+)?"#,
            with: "version: \(newVersion)+\(newBuild)",
            options: .regularExpression
        )
        
        try content.write(toFile: path, atomically: true, encoding: .utf8)
        logger.success("Set version to \(newVersion)+\(newBuild)")
    }
    
    // MARK: - React Native Projects
    
    /// Get version from package.json
    public func getVersionFromPackageJson(path: String) throws -> String {
        let data = try Data(contentsOf: URL(fileURLWithPath: path))
        guard let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
              let version = json["version"] as? String else {
            throw VersionError.versionNotFound
        }
        return version
    }
    
    /// Set version in package.json
    public func setVersionInPackageJson(path: String, version: String) throws {
        var content = try String(contentsOfFile: path, encoding: .utf8)
        
        content = content.replacingOccurrences(
            of: #"("version"\s*:\s*)"[^"]+""#,
            with: "$1\"\(version)\"",
            options: .regularExpression
        )
        
        try content.write(toFile: path, atomically: true, encoding: .utf8)
        logger.success("Set version to \(version) in package.json")
    }
    
    // MARK: - Auto Version Bumping
    
    /// Bump version based on bump type
    public func bumpVersion(
        currentVersion: String,
        bumpType: BumpType
    ) -> String {
        guard let semver = SemanticVersion(string: currentVersion) else {
            // Fallback for non-semver versions
            return currentVersion
        }
        
        let newVersion: SemanticVersion
        
        switch bumpType {
        case .major:
            newVersion = semver.bumpMajor()
        case .minor:
            newVersion = semver.bumpMinor()
        case .patch:
            newVersion = semver.bumpPatch()
        case .prerelease(let identifier):
            newVersion = semver.withPrerelease(identifier)
        case .build(let metadata):
            newVersion = semver.withBuild(metadata)
        }
        
        return newVersion.description
    }
    
    /// Get next build number
    public func getNextBuildNumber(
        current: Int,
        strategy: BuildNumberStrategy
    ) -> Int {
        switch strategy {
        case .increment:
            return current + 1
        case .dateTime:
            return BuildNumber.fromDateTime().value
        case .dateBuild(let index):
            return BuildNumber.fromDateBuild(buildIndex: index).value
        case .fixed(let value):
            return value
        case .gitCommitCount:
            if let result = try? processRunner.run("git rev-list --count HEAD"),
               let count = Int(result.stdout.trimmingCharacters(in: .whitespacesAndNewlines)) {
                return count
            }
            return current + 1
        }
    }
    
    // MARK: - Multi-Platform Version Sync
    
    /// Sync version across all platform files
    public func syncVersion(
        version: String,
        build: String,
        platforms: [Platform]
    ) throws {
        let currentDir = fileManager.currentDirectoryPath
        
        for platform in platforms {
            switch platform {
            case .ios, .macos:
                // Find Info.plist files
                let infoPlistPaths = findFiles(named: "Info.plist", in: currentDir)
                for path in infoPlistPaths {
                    try setVersionInInfoPlist(path: path, version: version, build: build)
                }
                
            case .android:
                // Find build.gradle files
                let gradlePaths = findFiles(named: "build.gradle", in: currentDir)
                for path in gradlePaths {
                    if let buildNum = Int(build) {
                        try setVersionInGradle(buildGradlePath: path, versionName: version, versionCode: buildNum)
                    }
                }
                
            case .flutter:
                let pubspecPath = "\(currentDir)/pubspec.yaml"
                if fileManager.fileExists(atPath: pubspecPath) {
                    if let buildNum = Int(build) {
                        try setVersionInPubspec(path: pubspecPath, version: version, build: buildNum)
                    }
                }
                
            case .reactNative:
                let packagePath = "\(currentDir)/package.json"
                if fileManager.fileExists(atPath: packagePath) {
                    try setVersionInPackageJson(path: packagePath, version: version)
                }
                
            default:
                break
            }
        }
        
        logger.success("Version synced across \(platforms.count) platforms")
    }
    
    // MARK: - Git Tags
    
    /// Create a git tag for the version
    public func createGitTag(
        version: String,
        message: String? = nil,
        push: Bool = false
    ) throws {
        let tagName = version.hasPrefix("v") ? version : "v\(version)"
        let tagMessage = message ?? "Release \(tagName)"
        
        // Create annotated tag
        _ = try processRunner.run(
            "git tag -a '\(tagName)' -m '\(tagMessage)'"
        )
        logger.success("Created tag: \(tagName)")
        
        if push {
            _ = try processRunner.run("git push origin '\(tagName)'")
            logger.success("Pushed tag: \(tagName)")
        }
    }
    
    /// Get latest git tag
    public func getLatestGitTag() -> String? {
        let result = try? processRunner.run("git describe --tags --abbrev=0 2>/dev/null")
        return result?.success == true ? result?.stdout.trimmingCharacters(in: .whitespacesAndNewlines) : nil
    }
    
    /// Get version from git tag
    public func getVersionFromGitTag(_ tag: String) -> SemanticVersion? {
        let versionString = tag.hasPrefix("v") ? String(tag.dropFirst()) : tag
        return SemanticVersion(string: versionString)
    }
    
    // MARK: - Helpers
    
    private func findFiles(named filename: String, in directory: String) -> [String] {
        var results: [String] = []
        
        guard let enumerator = fileManager.enumerator(atPath: directory) else {
            return results
        }
        
        while let path = enumerator.nextObject() as? String {
            if path.hasSuffix(filename) && !path.contains("Pods") && !path.contains("node_modules") {
                results.append("\(directory)/\(path)")
            }
        }
        
        return results
    }
}

// MARK: - Bump Type

/// Type of version bump
public enum BumpType: Sendable {
    case major
    case minor
    case patch
    case prerelease(String)
    case build(String)
}

// MARK: - Build Number Strategy

/// Strategy for generating build numbers
public enum BuildNumberStrategy: Sendable {
    case increment
    case dateTime
    case dateBuild(index: Int)
    case fixed(Int)
    case gitCommitCount
}

// MARK: - Version Errors

/// Errors that can occur during version management
public enum VersionError: LocalizedError {
    case versionNotFound
    case invalidVersionFormat
    case fileNotFound(String)
    case writeError(String)
    
    public var errorDescription: String? {
        switch self {
        case .versionNotFound:
            return "Version string not found in file"
        case .invalidVersionFormat:
            return "Invalid version format"
        case .fileNotFound(let path):
            return "File not found: \(path)"
        case .writeError(let message):
            return "Write error: \(message)"
        }
    }
}
