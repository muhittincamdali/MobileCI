// main.swift
// MobileCI - Complete Mobile CI/CD Toolkit
//
// A production-ready CI/CD command-line tool for mobile applications.
// Supports iOS, Android, Flutter, and React Native projects.

import Foundation
import ArgumentParser
import MobileCIKit

/// Main entry point for the MobileCI command-line tool.
/// Provides subcommands for building, testing, deploying, and linting mobile applications.
@main
struct MobileCI: AsyncParsableCommand {
    
    // MARK: - Command Configuration
    
    static let configuration = CommandConfiguration(
        commandName: "mobileci",
        abstract: "Complete CI/CD toolkit for mobile applications",
        discussion: """
            MobileCI is a comprehensive command-line tool designed to streamline
            continuous integration and deployment workflows for mobile applications.
            
            It supports multiple platforms including iOS, Android, Flutter, and
            React Native, with integrations for popular CI providers like GitHub Actions,
            Bitrise, and CircleCI.
            
            EXAMPLES:
              mobileci build --platform ios --scheme MyApp
              mobileci test --platform flutter --coverage
              mobileci deploy --target testflight --build-number 42
              mobileci lint --config .swiftlint.yml
              mobileci init --template ios-standard
            
            For detailed documentation, visit: https://github.com/muhittincamdali/MobileCI
            """,
        version: MobileCIVersion.current,
        subcommands: [
            BuildCommand.self,
            TestCommand.self,
            DeployCommand.self,
            LintCommand.self,
            InitCommand.self,
            ConfigCommand.self,
            CacheCommand.self,
            NotifyCommand.self,
            VersionBumpCommand.self,
            GenerateCommand.self,
            AnalyzeCommand.self,
            CleanCommand.self,
            DoctorCommand.self
        ],
        defaultSubcommand: nil
    )
    
    // MARK: - Global Options
    
    @Flag(name: .shortAndLong, help: "Enable verbose output for debugging")
    var verbose: Bool = false
    
    @Flag(name: .long, help: "Suppress all output except errors")
    var quiet: Bool = false
    
    @Option(name: .long, help: "Path to configuration file")
    var config: String?
    
    @Option(name: .long, help: "Working directory for commands")
    var workdir: String?
    
    @Flag(name: .long, help: "Run in dry-run mode without executing commands")
    var dryRun: Bool = false
    
    @Option(name: .long, help: "Output format (text, json, xml)")
    var format: OutputFormat = .text
}

/// Version information for MobileCI
public enum MobileCIVersion {
    public static let major = 2
    public static let minor = 0
    public static let patch = 0
    public static let prerelease: String? = nil
    
    public static var current: String {
        var version = "\(major).\(minor).\(patch)"
        if let prerelease = prerelease {
            version += "-\(prerelease)"
        }
        return version
    }
    
    public static var full: String {
        return """
            MobileCI v\(current)
            Build Date: \(buildDate)
            Swift Version: \(swiftVersion)
            Platform: \(platformInfo)
            """
    }
    
    private static var buildDate: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter.string(from: Date())
    }
    
    private static var swiftVersion: String {
        #if swift(>=5.10)
        return "5.10+"
        #elseif swift(>=5.9)
        return "5.9"
        #else
        return "5.8 or earlier"
        #endif
    }
    
    private static var platformInfo: String {
        #if os(macOS)
        return "macOS"
        #elseif os(Linux)
        return "Linux"
        #else
        return "Unknown"
        #endif
    }
}

/// Output format options for command results
public enum OutputFormat: String, ExpressibleByArgument, CaseIterable {
    case text
    case json
    case xml
    case markdown
    
    public static var allValueStrings: [String] {
        return allCases.map { $0.rawValue }
    }
}

// MARK: - Command Protocols

/// Protocol for commands that support platform selection
public protocol PlatformSelectable {
    var platform: Platform { get }
}

/// Protocol for commands that produce build artifacts
public protocol ArtifactProducing {
    var outputPath: String? { get }
    var artifactName: String? { get }
}

/// Protocol for commands that support progress reporting
public protocol ProgressReporting {
    func reportProgress(_ progress: Double, message: String)
}

// MARK: - Exit Codes

/// Standard exit codes for MobileCI commands
public enum ExitCode: Int32 {
    case success = 0
    case generalError = 1
    case missingDependency = 2
    case configurationError = 3
    case buildFailed = 10
    case testFailed = 11
    case deployFailed = 12
    case lintFailed = 13
    case networkError = 20
    case authenticationError = 21
    case timeoutError = 22
    case invalidInput = 30
    case fileNotFound = 31
    case permissionDenied = 32
    case cancelled = 130
}

// MARK: - Global Context

/// Shared context for all MobileCI operations
public final class MobileCIContext {
    public static let shared = MobileCIContext()
    
    public var isVerbose: Bool = false
    public var isQuiet: Bool = false
    public var isDryRun: Bool = false
    public var workingDirectory: URL
    public var configPath: String?
    public var outputFormat: OutputFormat = .text
    
    private init() {
        self.workingDirectory = URL(fileURLWithPath: FileManager.default.currentDirectoryPath)
    }
    
    public func configure(verbose: Bool, quiet: Bool, dryRun: Bool, workdir: String?, config: String?, format: OutputFormat) {
        self.isVerbose = verbose
        self.isQuiet = quiet
        self.isDryRun = dryRun
        self.configPath = config
        self.outputFormat = format
        
        if let workdir = workdir {
            self.workingDirectory = URL(fileURLWithPath: workdir)
        }
    }
}

// MARK: - Environment Detection

/// Detects the current CI environment
public struct CIEnvironment {
    public enum Provider: String, CaseIterable {
        case githubActions = "GitHub Actions"
        case bitrise = "Bitrise"
        case circleCI = "CircleCI"
        case jenkins = "Jenkins"
        case travisCI = "Travis CI"
        case azurePipelines = "Azure Pipelines"
        case gitlabCI = "GitLab CI"
        case teamcity = "TeamCity"
        case local = "Local"
        case unknown = "Unknown"
    }
    
    public static func detect() -> Provider {
        let env = ProcessInfo.processInfo.environment
        
        if env["GITHUB_ACTIONS"] == "true" {
            return .githubActions
        } else if env["BITRISE_IO"] == "true" {
            return .bitrise
        } else if env["CIRCLECI"] == "true" {
            return .circleCI
        } else if env["JENKINS_URL"] != nil {
            return .jenkins
        } else if env["TRAVIS"] == "true" {
            return .travisCI
        } else if env["TF_BUILD"] == "true" {
            return .azurePipelines
        } else if env["GITLAB_CI"] == "true" {
            return .gitlabCI
        } else if env["TEAMCITY_VERSION"] != nil {
            return .teamcity
        } else if env["CI"] == nil && env["CONTINUOUS_INTEGRATION"] == nil {
            return .local
        }
        
        return .unknown
    }
    
    public static var isCI: Bool {
        let provider = detect()
        return provider != .local && provider != .unknown
    }
    
    public static var provider: Provider {
        return detect()
    }
    
    public static func getVariable(_ name: String) -> String? {
        return ProcessInfo.processInfo.environment[name]
    }
    
    public static func requireVariable(_ name: String) throws -> String {
        guard let value = getVariable(name) else {
            throw MobileCIError.missingEnvironmentVariable(name)
        }
        return value
    }
}

// MARK: - Errors

/// Errors that can occur during MobileCI operations
public enum MobileCIError: LocalizedError {
    case missingEnvironmentVariable(String)
    case configurationNotFound(String)
    case invalidConfiguration(String)
    case buildFailed(String)
    case testFailed(String)
    case deploymentFailed(String)
    case lintFailed(String)
    case processExecutionFailed(String, Int32)
    case fileNotFound(String)
    case networkError(String)
    case authenticationFailed(String)
    case timeout(String)
    case unsupportedPlatform(String)
    case dependencyMissing(String)
    case invalidArgument(String)
    case cancelled
    
    public var errorDescription: String? {
        switch self {
        case .missingEnvironmentVariable(let name):
            return "Required environment variable '\(name)' is not set"
        case .configurationNotFound(let path):
            return "Configuration file not found at '\(path)'"
        case .invalidConfiguration(let message):
            return "Invalid configuration: \(message)"
        case .buildFailed(let message):
            return "Build failed: \(message)"
        case .testFailed(let message):
            return "Tests failed: \(message)"
        case .deploymentFailed(let message):
            return "Deployment failed: \(message)"
        case .lintFailed(let message):
            return "Lint failed: \(message)"
        case .processExecutionFailed(let command, let code):
            return "Process '\(command)' failed with exit code \(code)"
        case .fileNotFound(let path):
            return "File not found: \(path)"
        case .networkError(let message):
            return "Network error: \(message)"
        case .authenticationFailed(let message):
            return "Authentication failed: \(message)"
        case .timeout(let operation):
            return "Operation timed out: \(operation)"
        case .unsupportedPlatform(let platform):
            return "Unsupported platform: \(platform)"
        case .dependencyMissing(let dependency):
            return "Required dependency '\(dependency)' is not installed"
        case .invalidArgument(let message):
            return "Invalid argument: \(message)"
        case .cancelled:
            return "Operation was cancelled"
        }
    }
    
    public var exitCode: ExitCode {
        switch self {
        case .missingEnvironmentVariable, .configurationNotFound, .invalidConfiguration:
            return .configurationError
        case .buildFailed:
            return .buildFailed
        case .testFailed:
            return .testFailed
        case .deploymentFailed:
            return .deployFailed
        case .lintFailed:
            return .lintFailed
        case .processExecutionFailed:
            return .generalError
        case .fileNotFound:
            return .fileNotFound
        case .networkError:
            return .networkError
        case .authenticationFailed:
            return .authenticationError
        case .timeout:
            return .timeoutError
        case .unsupportedPlatform, .invalidArgument:
            return .invalidInput
        case .dependencyMissing:
            return .missingDependency
        case .cancelled:
            return .cancelled
        }
    }
}

// MARK: - Signal Handling

/// Handles system signals for graceful shutdown
public final class SignalHandler {
    public static let shared = SignalHandler()
    
    private var handlers: [() -> Void] = []
    private var isSetup = false
    
    private init() {}
    
    public func setup() {
        guard !isSetup else { return }
        isSetup = true
        
        signal(SIGINT) { _ in
            SignalHandler.shared.handleSignal()
        }
        
        signal(SIGTERM) { _ in
            SignalHandler.shared.handleSignal()
        }
    }
    
    public func addHandler(_ handler: @escaping () -> Void) {
        handlers.append(handler)
    }
    
    private func handleSignal() {
        for handler in handlers.reversed() {
            handler()
        }
        exit(ExitCode.cancelled.rawValue)
    }
}
