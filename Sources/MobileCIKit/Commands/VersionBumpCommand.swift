// VersionBumpCommand.swift
// MobileCIKit
//
// Version and build number management command.

import Foundation
import ArgumentParser

/// Command for version and build number management
public struct VersionBumpCommand: AsyncParsableCommand {
    public static let configuration = CommandConfiguration(
        commandName: "version-bump",
        abstract: "Bump version and build numbers",
        discussion: """
            Manage version numbers across iOS, Android, Flutter, and React Native projects.
            Supports semantic versioning and various build number strategies.
            
            EXAMPLES:
              mobileci version-bump --bump minor
              mobileci version-bump --set 2.0.0 --build-number datetime
              mobileci version-bump --bump patch --tag --push
              mobileci version-bump --sync --platforms ios,android
            """
    )
    
    @Option(name: .long, help: "Bump type (major, minor, patch)")
    var bump: String?
    
    @Option(name: .long, help: "Set specific version")
    var set: String?
    
    @Option(name: .long, help: "Set specific build number")
    var buildNumber: String?
    
    @Option(name: .long, help: "Build number strategy (increment, datetime, git-count)")
    var buildStrategy: String = "increment"
    
    @Option(name: .long, help: "Platforms to update (comma-separated)")
    var platforms: String?
    
    @Flag(name: .long, help: "Sync version across all platforms")
    var sync: Bool = false
    
    @Flag(name: .long, help: "Create git tag")
    var tag: Bool = false
    
    @Flag(name: .long, help: "Push tag to remote")
    var push: Bool = false
    
    @Flag(name: .long, help: "Update changelog")
    var changelog: Bool = false
    
    @Flag(name: .long, help: "Dry run mode")
    var dryRun: Bool = false
    
    @Flag(name: .shortAndLong, help: "Verbose output")
    var verbose: Bool = false
    
    public init() {}
    
    public func run() async throws {
        let logger = Logger.shared
        let versionManager = VersionManager.shared
        
        if verbose {
            logger.setMinimumLevel(.debug)
        }
        
        // Determine current version
        var currentVersion = "1.0.0"
        var currentBuild = 1
        
        // Try to detect from project files
        if FileManager.default.fileExists(atPath: "pubspec.yaml") {
            let (v, b) = try versionManager.getVersionFromPubspec(path: "pubspec.yaml")
            currentVersion = v
            currentBuild = b
        } else if FileManager.default.fileExists(atPath: "package.json") {
            currentVersion = try versionManager.getVersionFromPackageJson(path: "package.json")
        }
        
        // Determine new version
        var newVersion = currentVersion
        
        if let setVersion = set {
            newVersion = setVersion
        } else if let bumpType = bump {
            let type: BumpType
            switch bumpType.lowercased() {
            case "major": type = .major
            case "minor": type = .minor
            case "patch": type = .patch
            default: type = .patch
            }
            newVersion = versionManager.bumpVersion(currentVersion: currentVersion, bumpType: type)
        }
        
        // Determine new build number
        var newBuild = currentBuild
        
        if let buildNum = buildNumber {
            newBuild = Int(buildNum) ?? currentBuild
        } else {
            let strategy: BuildNumberStrategy
            switch buildStrategy {
            case "datetime": strategy = .dateTime
            case "git-count": strategy = .gitCommitCount
            case "date-build": strategy = .dateBuild(index: 1)
            default: strategy = .increment
            }
            newBuild = versionManager.getNextBuildNumber(current: currentBuild, strategy: strategy)
        }
        
        logger.info("Version: \(currentVersion) → \(newVersion)")
        logger.info("Build: \(currentBuild) → \(newBuild)")
        
        if dryRun {
            logger.info("[DRY RUN] Would update version files")
            return
        }
        
        // Update version files
        if sync {
            let targetPlatforms: [Platform]
            if let platforms = platforms {
                targetPlatforms = platforms.components(separatedBy: ",").compactMap { Platform(rawValue: $0.trimmingCharacters(in: .whitespaces)) }
            } else {
                targetPlatforms = [.ios, .android, .flutter, .reactNative]
            }
            
            try versionManager.syncVersion(
                version: newVersion,
                build: String(newBuild),
                platforms: targetPlatforms
            )
        }
        
        // Update changelog
        if changelog {
            let changelogGen = ChangelogGenerator.shared
            try changelogGen.updateChangelogFile(
                version: newVersion,
                from: versionManager.getLatestGitTag()
            )
        }
        
        // Create git tag
        if tag {
            try versionManager.createGitTag(
                version: newVersion,
                message: "Release \(newVersion)",
                push: push
            )
        }
        
        logger.success("Version updated to \(newVersion) (build \(newBuild))")
    }
}

/// Command for generating changelogs
public struct GenerateCommand: AsyncParsableCommand {
    public static let configuration = CommandConfiguration(
        commandName: "generate",
        abstract: "Generate CI workflows and changelogs",
        subcommands: [
            GenerateWorkflowCommand.self,
            GenerateChangelogCommand.self
        ]
    )
    
    public init() {}
}

public struct GenerateWorkflowCommand: AsyncParsableCommand {
    public static let configuration = CommandConfiguration(
        commandName: "workflow",
        abstract: "Generate CI workflow configurations"
    )
    
    @Option(name: .long, help: "CI provider (github, gitlab, bitrise, circleci)")
    var provider: String = "github"
    
    @Option(name: .long, help: "Project name")
    var name: String = "App"
    
    @Option(name: .long, help: "Platform")
    var platform: String = "ios"
    
    @Option(name: .long, help: "Output directory")
    var output: String = "."
    
    public init() {}
    
    public func run() async throws {
        let generator = CIWorkflowGenerator.shared
        let logger = Logger.shared
        
        let ciProvider = CIProvider(rawValue: provider) ?? .githubActions
        let targetPlatform = Platform(rawValue: platform) ?? .ios
        
        var config = WorkflowConfig.default
        config.projectName = name
        config.platform = targetPlatform
        
        try generator.saveWorkflow(
            provider: ciProvider,
            config: config,
            basePath: output
        )
        
        logger.success("Generated \(ciProvider.displayName) workflow")
    }
}

public struct GenerateChangelogCommand: AsyncParsableCommand {
    public static let configuration = CommandConfiguration(
        commandName: "changelog",
        abstract: "Generate changelog from git commits"
    )
    
    @Option(name: .long, help: "Version for changelog")
    var version: String = "Unreleased"
    
    @Option(name: .long, help: "Starting tag/commit")
    var from: String?
    
    @Option(name: .long, help: "Output format (markdown, keep-a-changelog, json)")
    var format: String = "markdown"
    
    @Option(name: .long, help: "Output file")
    var output: String?
    
    public init() {}
    
    public func run() async throws {
        let generator = ChangelogGenerator.shared
        let logger = Logger.shared
        
        let changelogFormat = ChangelogFormat(rawValue: format) ?? .markdown
        
        let changelog = try generator.generateChangelog(
            version: version,
            from: from,
            config: .default,
            format: changelogFormat
        )
        
        if let output = output {
            try changelog.write(toFile: output, atomically: true, encoding: .utf8)
            logger.success("Changelog written to \(output)")
        } else {
            print(changelog)
        }
    }
}

/// Placeholder commands for completeness
public struct TestCommand: AsyncParsableCommand {
    public static let configuration = CommandConfiguration(
        commandName: "test",
        abstract: "Run tests for mobile applications"
    )
    
    @Option(name: .shortAndLong, help: "Platform")
    var platform: Platform = .ios
    
    @Option(name: .long, help: "Scheme")
    var scheme: String?
    
    @Flag(name: .long, help: "Generate coverage")
    var coverage: Bool = false
    
    @Flag(name: .long, help: "Parallel testing")
    var parallel: Bool = false
    
    @Flag(name: .shortAndLong, help: "Verbose output")
    var verbose: Bool = false
    
    public init() {}
    
    public func run() async throws {
        let logger = Logger.shared
        logger.info("Running tests...")
        
        var command = "xcodebuild test"
        if let scheme = scheme {
            command += " -scheme '\(scheme)'"
        }
        command += " -destination 'platform=iOS Simulator,name=iPhone 15 Pro'"
        
        if coverage {
            command += " -enableCodeCoverage YES"
        }
        
        let result = try ProcessRunner.shared.run(command, options: .default.with(printOutput: true))
        
        if result.success {
            logger.success("Tests passed!")
        } else {
            logger.error("Tests failed")
            throw MobileCIError.testFailed(result.stderr)
        }
    }
}

public struct LintCommand: AsyncParsableCommand {
    public static let configuration = CommandConfiguration(
        commandName: "lint",
        abstract: "Lint code using SwiftLint"
    )
    
    @Option(name: .long, help: "SwiftLint config path")
    var config: String?
    
    @Flag(name: .long, help: "Fix violations")
    var fix: Bool = false
    
    @Flag(name: .long, help: "Strict mode")
    var strict: Bool = false
    
    public init() {}
    
    public func run() async throws {
        let logger = Logger.shared
        logger.info("Running SwiftLint...")
        
        var command = "swiftlint"
        
        if fix {
            command = "swiftlint --fix && swiftlint"
        }
        
        if let config = config {
            command += " --config '\(config)'"
        }
        
        if strict {
            command += " --strict"
        }
        
        let result = try ProcessRunner.shared.run(command, options: .default.with(printOutput: true))
        
        if result.success {
            logger.success("Lint passed!")
        } else {
            logger.error("Lint failed")
        }
    }
}

public struct InitCommand: AsyncParsableCommand {
    public static let configuration = CommandConfiguration(
        commandName: "init",
        abstract: "Initialize MobileCI configuration"
    )
    
    @Option(name: .long, help: "Platform")
    var platform: String = "ios"
    
    @Option(name: .long, help: "Template")
    var template: String = "standard"
    
    @Option(name: .long, help: "CI provider")
    var ci: String?
    
    public init() {}
    
    public func run() async throws {
        let logger = Logger.shared
        logger.info("Initializing MobileCI...")
        
        // Generate config file
        let config = """
            # mobileci.yml
            project:
              name: App
              platform: \(platform)
            
            build:
              configuration: Release
              clean: false
            
            test:
              coverage: true
              parallel: false
            """
        
        try config.write(toFile: "mobileci.yml", atomically: true, encoding: .utf8)
        logger.success("Created mobileci.yml")
        
        // Generate CI workflow if specified
        if let ci = ci {
            let generator = CIWorkflowGenerator.shared
            let provider = CIProvider(rawValue: ci) ?? .githubActions
            
            try generator.saveWorkflow(
                provider: provider,
                config: .default
            )
        }
        
        logger.success("MobileCI initialized!")
    }
}

public struct ConfigCommand: AsyncParsableCommand {
    public static let configuration = CommandConfiguration(
        commandName: "config",
        abstract: "Manage MobileCI configuration"
    )
    
    @Flag(name: .long, help: "Show current configuration")
    var show: Bool = false
    
    public init() {}
    
    public func run() async throws {
        let logger = Logger.shared
        
        if FileManager.default.fileExists(atPath: "mobileci.yml") {
            let content = try String(contentsOfFile: "mobileci.yml", encoding: .utf8)
            print(content)
        } else {
            logger.warning("No mobileci.yml found. Run 'mobileci init' to create one.")
        }
    }
}

public struct CacheCommand: AsyncParsableCommand {
    public static let configuration = CommandConfiguration(
        commandName: "cache",
        abstract: "Manage build caches"
    )
    
    @Flag(name: .long, help: "Clear all caches")
    var clear: Bool = false
    
    public init() {}
    
    public func run() async throws {
        let logger = Logger.shared
        
        if clear {
            _ = try? ProcessRunner.shared.run("rm -rf DerivedData")
            _ = try? ProcessRunner.shared.run("rm -rf ~/Library/Developer/Xcode/DerivedData/*")
            logger.success("Caches cleared!")
        }
    }
}

public struct NotifyCommand: AsyncParsableCommand {
    public static let configuration = CommandConfiguration(
        commandName: "notify",
        abstract: "Send build notifications"
    )
    
    @Option(name: .long, help: "Slack webhook URL")
    var slack: String?
    
    @Option(name: .long, help: "Message")
    var message: String = "Build completed"
    
    @Option(name: .long, help: "Status (success, failure)")
    var status: String = "success"
    
    public init() {}
    
    public func run() async throws {
        let logger = Logger.shared
        
        if let webhook = slack ?? ProcessInfo.processInfo.environment["SLACK_WEBHOOK"] {
            let emoji = status == "success" ? "✅" : "❌"
            let payload = """
                {"text": "\(emoji) \(message)"}
                """
            
            let command = "curl -X POST -H 'Content-type: application/json' --data '\(payload)' '\(webhook)'"
            _ = try ProcessRunner.shared.run(command)
            logger.success("Notification sent!")
        } else {
            logger.warning("No Slack webhook configured")
        }
    }
}

public struct AnalyzeCommand: AsyncParsableCommand {
    public static let configuration = CommandConfiguration(
        commandName: "analyze",
        abstract: "Analyze code quality"
    )
    
    public init() {}
    
    public func run() async throws {
        let logger = Logger.shared
        logger.info("Analyzing code...")
        
        let result = try ProcessRunner.shared.run(
            "xcodebuild analyze -scheme App -destination 'platform=iOS Simulator,name=iPhone 15 Pro'",
            options: .default.with(printOutput: true)
        )
        
        if result.success {
            logger.success("Analysis complete!")
        }
    }
}

public struct CleanCommand: AsyncParsableCommand {
    public static let configuration = CommandConfiguration(
        commandName: "clean",
        abstract: "Clean build artifacts"
    )
    
    @Flag(name: .long, help: "Deep clean including DerivedData")
    var deep: Bool = false
    
    public init() {}
    
    public func run() async throws {
        let logger = Logger.shared
        logger.info("Cleaning...")
        
        _ = try? ProcessRunner.shared.run("xcodebuild clean")
        
        if deep {
            _ = try? ProcessRunner.shared.run("rm -rf DerivedData")
            _ = try? ProcessRunner.shared.run("rm -rf build")
        }
        
        logger.success("Clean complete!")
    }
}

public struct DoctorCommand: AsyncParsableCommand {
    public static let configuration = CommandConfiguration(
        commandName: "doctor",
        abstract: "Check development environment"
    )
    
    public init() {}
    
    public func run() async throws {
        let logger = Logger.shared
        let runner = ProcessRunner.shared
        
        logger.info("MobileCI Doctor 🏥")
        logger.info("Checking development environment...\n")
        
        // Xcode
        if let xcodeResult = try? runner.run("xcode-select -p"), xcodeResult.success {
            logger.success("✅ Xcode: \(xcodeResult.stdout.trimmingCharacters(in: .whitespacesAndNewlines))")
        } else {
            logger.error("❌ Xcode: Not installed")
        }
        
        // Swift
        if let swiftResult = try? runner.run("swift --version"), swiftResult.success {
            let version = swiftResult.stdout.components(separatedBy: "\n").first ?? ""
            logger.success("✅ Swift: \(version)")
        } else {
            logger.error("❌ Swift: Not found")
        }
        
        // SwiftLint
        if runner.commandExists("swiftlint") {
            logger.success("✅ SwiftLint: Installed")
        } else {
            logger.warning("⚠️  SwiftLint: Not installed (optional)")
        }
        
        // CocoaPods
        if runner.commandExists("pod") {
            logger.success("✅ CocoaPods: Installed")
        } else {
            logger.warning("⚠️  CocoaPods: Not installed (optional)")
        }
        
        // Certificates
        if let certResult = try? runner.run("security find-identity -v -p codesigning"), certResult.success {
            let certCount = certResult.stdout.components(separatedBy: "\n").filter { $0.contains(")") }.count
            if certCount > 0 {
                logger.success("✅ Certificates: \(certCount) signing identity(s) found")
            } else {
                logger.warning("⚠️  Certificates: No signing identities found")
            }
        }
        
        // CI Environment
        let ciEnv = CIEnvironment.detect()
        logger.info("\n📍 Environment: \(ciEnv.rawValue)")
        
        logger.info("\n✨ Doctor check complete!")
    }
}
