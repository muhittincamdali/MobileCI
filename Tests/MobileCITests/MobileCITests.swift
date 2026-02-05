// MobileCITests.swift
// MobileCITests
//
// Unit tests for MobileCI framework.

import XCTest
@testable import MobileCIKit

final class MobileCITests: XCTestCase {
    
    // MARK: - Semantic Version Tests
    
    func testSemanticVersionParsing() {
        let version = SemanticVersion(string: "1.2.3")
        XCTAssertNotNil(version)
        XCTAssertEqual(version?.major, 1)
        XCTAssertEqual(version?.minor, 2)
        XCTAssertEqual(version?.patch, 3)
    }
    
    func testSemanticVersionWithPrerelease() {
        let version = SemanticVersion(string: "1.2.3-beta.1")
        XCTAssertNotNil(version)
        XCTAssertEqual(version?.prerelease, "beta.1")
    }
    
    func testSemanticVersionWithBuild() {
        let version = SemanticVersion(string: "1.2.3+build.456")
        XCTAssertNotNil(version)
        XCTAssertEqual(version?.build, "build.456")
    }
    
    func testSemanticVersionBumpMajor() {
        let version = SemanticVersion(major: 1, minor: 2, patch: 3)
        let bumped = version.bumpMajor()
        XCTAssertEqual(bumped.major, 2)
        XCTAssertEqual(bumped.minor, 0)
        XCTAssertEqual(bumped.patch, 0)
    }
    
    func testSemanticVersionBumpMinor() {
        let version = SemanticVersion(major: 1, minor: 2, patch: 3)
        let bumped = version.bumpMinor()
        XCTAssertEqual(bumped.major, 1)
        XCTAssertEqual(bumped.minor, 3)
        XCTAssertEqual(bumped.patch, 0)
    }
    
    func testSemanticVersionBumpPatch() {
        let version = SemanticVersion(major: 1, minor: 2, patch: 3)
        let bumped = version.bumpPatch()
        XCTAssertEqual(bumped.major, 1)
        XCTAssertEqual(bumped.minor, 2)
        XCTAssertEqual(bumped.patch, 4)
    }
    
    func testSemanticVersionComparison() {
        let v1 = SemanticVersion(major: 1, minor: 2, patch: 3)
        let v2 = SemanticVersion(major: 1, minor: 2, patch: 4)
        let v3 = SemanticVersion(major: 2, minor: 0, patch: 0)
        
        XCTAssertTrue(v1 < v2)
        XCTAssertTrue(v2 < v3)
        XCTAssertTrue(v1 < v3)
    }
    
    // MARK: - Build Number Tests
    
    func testBuildNumberIncrement() {
        let build = BuildNumber(value: 100)
        let incremented = build.increment()
        XCTAssertEqual(incremented.value, 101)
    }
    
    func testBuildNumberFromDateTime() {
        let build = BuildNumber.fromDateTime()
        XCTAssertGreaterThan(build.value, 202400000000)
    }
    
    // MARK: - Platform Tests
    
    func testPlatformDisplayNames() {
        XCTAssertEqual(Platform.ios.displayName, "iOS")
        XCTAssertEqual(Platform.macos.displayName, "macOS")
        XCTAssertEqual(Platform.android.displayName, "Android")
        XCTAssertEqual(Platform.flutter.displayName, "Flutter")
    }
    
    func testPlatformIsApple() {
        XCTAssertTrue(Platform.ios.isApplePlatform)
        XCTAssertTrue(Platform.macos.isApplePlatform)
        XCTAssertTrue(Platform.watchos.isApplePlatform)
        XCTAssertFalse(Platform.android.isApplePlatform)
        XCTAssertFalse(Platform.flutter.isApplePlatform)
    }
    
    // MARK: - Build Configuration Tests
    
    func testBuildConfigurationXcode() {
        XCTAssertEqual(BuildConfiguration.debug.xcodeBuildConfiguration, "Debug")
        XCTAssertEqual(BuildConfiguration.release.xcodeBuildConfiguration, "Release")
    }
    
    func testBuildConfigurationGradle() {
        XCTAssertEqual(BuildConfiguration.debug.gradleBuildType, "debug")
        XCTAssertEqual(BuildConfiguration.release.gradleBuildType, "release")
    }
    
    // MARK: - Export Method Tests
    
    func testExportMethodPlistValues() {
        XCTAssertEqual(ExportMethod.appStore.plistValue, "app-store")
        XCTAssertEqual(ExportMethod.adHoc.plistValue, "ad-hoc")
        XCTAssertEqual(ExportMethod.enterprise.plistValue, "enterprise")
        XCTAssertEqual(ExportMethod.development.plistValue, "development")
    }
    
    // MARK: - Export Options Tests
    
    func testExportOptionsToPlist() {
        let options = ExportOptions(
            method: .appStore,
            teamId: "ABC123",
            uploadBitcode: false,
            uploadSymbols: true
        )
        
        let plist = options.toPlist()
        XCTAssertTrue(plist.contains("app-store"))
        XCTAssertTrue(plist.contains("ABC123"))
    }
    
    // MARK: - CI Environment Tests
    
    func testCIEnvironmentDetection() {
        // When running locally, should detect as local
        let env = CIEnvironment.detect()
        // This test will vary based on where it's run
        XCTAssertNotNil(env)
    }
    
    // MARK: - Process Runner Tests
    
    func testProcessRunnerCommandExists() {
        let runner = ProcessRunner.shared
        XCTAssertTrue(runner.commandExists("ls"))
        XCTAssertTrue(runner.commandExists("echo"))
        XCTAssertFalse(runner.commandExists("nonexistent_command_12345"))
    }
    
    func testProcessRunnerBasicCommand() throws {
        let runner = ProcessRunner.shared
        let result = try runner.run("echo 'Hello, World!'")
        XCTAssertTrue(result.success)
        XCTAssertTrue(result.stdout.contains("Hello"))
    }
    
    func testProcessRunnerFailingCommand() throws {
        let runner = ProcessRunner.shared
        let result = try runner.run("exit 1")
        XCTAssertFalse(result.success)
        XCTAssertEqual(result.exitCode, 1)
    }
    
    // MARK: - Logger Tests
    
    func testLoggerBasic() {
        let logger = Logger.shared
        // Just ensure no crash
        logger.info("Test message")
        logger.debug("Debug message")
        logger.warning("Warning message")
    }
    
    // MARK: - Changelog Tests
    
    func testCommitTypePriority() {
        XCTAssertLessThan(CommitType.breaking.priority, CommitType.feat.priority)
        XCTAssertLessThan(CommitType.feat.priority, CommitType.fix.priority)
        XCTAssertLessThan(CommitType.fix.priority, CommitType.chore.priority)
    }
    
    func testCommitTypeEmoji() {
        XCTAssertEqual(CommitType.feat.emoji, "✨")
        XCTAssertEqual(CommitType.fix.emoji, "🐛")
        XCTAssertEqual(CommitType.docs.emoji, "📚")
    }
    
    // MARK: - CI Provider Tests
    
    func testCIProviderConfigPaths() {
        XCTAssertEqual(CIProvider.githubActions.configPath, ".github/workflows/ios.yml")
        XCTAssertEqual(CIProvider.gitlabCI.configPath, ".gitlab-ci.yml")
        XCTAssertEqual(CIProvider.circleCI.configPath, ".circleci/config.yml")
    }
    
    // MARK: - Workflow Config Tests
    
    func testWorkflowConfigDefault() {
        let config = WorkflowConfig.default
        XCTAssertEqual(config.projectName, "App")
        XCTAssertEqual(config.platform, .ios)
        XCTAssertTrue(config.enableCache)
        XCTAssertTrue(config.enableTesting)
    }
}
