// Models.swift
// MobileCIKit
//
// Core data models for MobileCI framework.

import Foundation
import ArgumentParser

// MARK: - Platform

/// Supported mobile platforms
public enum Platform: String, Codable, CaseIterable, ExpressibleByArgument, Sendable {
    case ios = "ios"
    case macos = "macos"
    case watchos = "watchos"
    case tvos = "tvos"
    case visionos = "visionos"
    case android = "android"
    case flutter = "flutter"
    case reactNative = "react-native"
    case multiplatform = "multiplatform"
    
    public var displayName: String {
        switch self {
        case .ios: return "iOS"
        case .macos: return "macOS"
        case .watchos: return "watchOS"
        case .tvos: return "tvOS"
        case .visionos: return "visionOS"
        case .android: return "Android"
        case .flutter: return "Flutter"
        case .reactNative: return "React Native"
        case .multiplatform: return "Multiplatform"
        }
    }
    
    public var defaultXcodeDestination: String? {
        switch self {
        case .ios: return "platform=iOS Simulator,name=iPhone 15 Pro,OS=17.0"
        case .macos: return "platform=macOS"
        case .watchos: return "platform=watchOS Simulator,name=Apple Watch Series 9 (45mm)"
        case .tvos: return "platform=tvOS Simulator,name=Apple TV 4K (3rd generation)"
        case .visionos: return "platform=visionOS Simulator,name=Apple Vision Pro"
        default: return nil
        }
    }
    
    public var isApplePlatform: Bool {
        switch self {
        case .ios, .macos, .watchos, .tvos, .visionos:
            return true
        default:
            return false
        }
    }
}

// MARK: - Build Configuration

/// Build configuration types
public enum BuildConfiguration: String, Codable, ExpressibleByArgument, Sendable {
    case debug = "debug"
    case release = "release"
    case staging = "staging"
    case production = "production"
    
    public var xcodeBuildConfiguration: String {
        switch self {
        case .debug: return "Debug"
        case .release, .production: return "Release"
        case .staging: return "Staging"
        }
    }
    
    public var gradleBuildType: String {
        switch self {
        case .debug: return "debug"
        case .release, .production: return "release"
        case .staging: return "staging"
        }
    }
    
    public var flutterMode: String {
        switch self {
        case .debug: return "--debug"
        case .release, .production: return "--release"
        case .staging: return "--profile"
        }
    }
}

// MARK: - Export Method

/// IPA export methods
public enum ExportMethod: String, Codable, ExpressibleByArgument, Sendable {
    case appStore = "app-store"
    case adHoc = "ad-hoc"
    case enterprise = "enterprise"
    case development = "development"
    case developerID = "developer-id"
    
    public var plistValue: String {
        switch self {
        case .appStore: return "app-store"
        case .adHoc: return "ad-hoc"
        case .enterprise: return "enterprise"
        case .development: return "development"
        case .developerID: return "developer-id"
        }
    }
}

// MARK: - Export Options

/// Export options for creating IPA
public struct ExportOptions: Codable, Sendable {
    public var method: ExportMethod
    public var teamId: String?
    public var signingStyle: SigningStyle
    public var signingIdentity: String?
    public var provisioningProfiles: [String: String]?
    public var uploadBitcode: Bool
    public var uploadSymbols: Bool
    public var compileBitcode: Bool
    public var thinning: String
    public var stripSwiftSymbols: Bool
    
    public enum SigningStyle: String, Codable, Sendable {
        case automatic
        case manual
    }
    
    public init(
        method: ExportMethod,
        teamId: String? = nil,
        signingStyle: SigningStyle = .automatic,
        signingIdentity: String? = nil,
        provisioningProfiles: [String: String]? = nil,
        uploadBitcode: Bool = false,
        uploadSymbols: Bool = true,
        compileBitcode: Bool = false,
        thinning: String = "<none>",
        stripSwiftSymbols: Bool = true
    ) {
        self.method = method
        self.teamId = teamId
        self.signingStyle = signingStyle
        self.signingIdentity = signingIdentity
        self.provisioningProfiles = provisioningProfiles
        self.uploadBitcode = uploadBitcode
        self.uploadSymbols = uploadSymbols
        self.compileBitcode = compileBitcode
        self.thinning = thinning
        self.stripSwiftSymbols = stripSwiftSymbols
    }
    
    public func toPlist() -> String {
        var dict: [String: Any] = [
            "method": method.plistValue,
            "uploadBitcode": uploadBitcode,
            "uploadSymbols": uploadSymbols,
            "compileBitcode": compileBitcode,
            "thinning": thinning,
            "stripSwiftSymbols": stripSwiftSymbols,
            "signingStyle": signingStyle.rawValue
        ]
        
        if let teamId = teamId {
            dict["teamID"] = teamId
        }
        
        if let identity = signingIdentity {
            dict["signingCertificate"] = identity
        }
        
        if let profiles = provisioningProfiles {
            dict["provisioningProfiles"] = profiles
        }
        
        // Convert to plist XML
        var plist = """
            <?xml version="1.0" encoding="UTF-8"?>
            <!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
            <plist version="1.0">
            <dict>
            """
        
        for (key, value) in dict {
            plist += "\n\t<key>\(key)</key>"
            
            switch value {
            case let boolValue as Bool:
                plist += boolValue ? "\n\t<true/>" : "\n\t<false/>"
            case let stringValue as String:
                plist += "\n\t<string>\(stringValue)</string>"
            case let dictValue as [String: String]:
                plist += "\n\t<dict>"
                for (k, v) in dictValue {
                    plist += "\n\t\t<key>\(k)</key>"
                    plist += "\n\t\t<string>\(v)</string>"
                }
                plist += "\n\t</dict>"
            default:
                break
            }
        }
        
        plist += """
            
            </dict>
            </plist>
            """
        
        return plist
    }
}

// MARK: - Build Result

/// Result of a build operation
public struct BuildResult: Sendable {
    public let success: Bool
    public let platform: Platform
    public let configuration: BuildConfiguration
    public let artifactPath: String?
    public let duration: TimeInterval
    public let startTime: Date
    public let endTime: Date
    public let warnings: [BuildDiagnostic]
    public let errors: [BuildDiagnostic]
    
    public init(
        success: Bool,
        platform: Platform,
        configuration: BuildConfiguration,
        artifactPath: String? = nil,
        duration: TimeInterval,
        startTime: Date,
        endTime: Date,
        warnings: [BuildDiagnostic] = [],
        errors: [BuildDiagnostic] = []
    ) {
        self.success = success
        self.platform = platform
        self.configuration = configuration
        self.artifactPath = artifactPath
        self.duration = duration
        self.startTime = startTime
        self.endTime = endTime
        self.warnings = warnings
        self.errors = errors
    }
}

/// Build diagnostic (warning or error)
public struct BuildDiagnostic: Sendable {
    public let level: Level
    public let message: String
    public let file: String?
    public let line: Int?
    public let column: Int?
    
    public enum Level: String, Sendable {
        case warning
        case error
    }
    
    public init(level: Level, message: String, file: String? = nil, line: Int? = nil, column: Int? = nil) {
        self.level = level
        self.message = message
        self.file = file
        self.line = line
        self.column = column
    }
}

// MARK: - Package Manager

/// Supported package managers
public enum PackageManager: String, Codable, Sendable {
    case spm = "Swift Package Manager"
    case cocoapods = "CocoaPods"
    case carthage = "Carthage"
    case gradle = "Gradle"
    case maven = "Maven"
    case npm = "npm"
    case yarn = "Yarn"
    case pnpm = "pnpm"
    case pub = "Pub"
    
    public var installCommand: String {
        switch self {
        case .spm: return "swift package resolve"
        case .cocoapods: return "bundle exec pod install"
        case .carthage: return "carthage bootstrap --use-xcframeworks --cache-builds"
        case .gradle: return "./gradlew dependencies"
        case .maven: return "mvn dependency:resolve"
        case .npm: return "npm ci"
        case .yarn: return "yarn install --frozen-lockfile"
        case .pnpm: return "pnpm install --frozen-lockfile"
        case .pub: return "flutter pub get"
        }
    }
}

// MARK: - Test Result

/// Result of a test run
public struct TestResult: Sendable {
    public let success: Bool
    public let totalTests: Int
    public let passedTests: Int
    public let failedTests: Int
    public let skippedTests: Int
    public let duration: TimeInterval
    public let coverage: Double?
    public let failures: [TestFailure]
    
    public init(
        success: Bool,
        totalTests: Int,
        passedTests: Int,
        failedTests: Int,
        skippedTests: Int,
        duration: TimeInterval,
        coverage: Double? = nil,
        failures: [TestFailure] = []
    ) {
        self.success = success
        self.totalTests = totalTests
        self.passedTests = passedTests
        self.failedTests = failedTests
        self.skippedTests = skippedTests
        self.duration = duration
        self.coverage = coverage
        self.failures = failures
    }
}

/// Test failure details
public struct TestFailure: Sendable {
    public let testName: String
    public let className: String
    public let message: String
    public let file: String?
    public let line: Int?
    
    public init(testName: String, className: String, message: String, file: String? = nil, line: Int? = nil) {
        self.testName = testName
        self.className = className
        self.message = message
        self.file = file
        self.line = line
    }
}

// MARK: - App Info

/// Application information
public struct AppInfo: Codable, Sendable {
    public let name: String
    public let bundleId: String
    public let version: String
    public let buildNumber: String
    public let minimumOSVersion: String?
    public let supportedPlatforms: [Platform]
    public let teamId: String?
    
    public init(
        name: String,
        bundleId: String,
        version: String,
        buildNumber: String,
        minimumOSVersion: String? = nil,
        supportedPlatforms: [Platform] = [.ios],
        teamId: String? = nil
    ) {
        self.name = name
        self.bundleId = bundleId
        self.version = version
        self.buildNumber = buildNumber
        self.minimumOSVersion = minimumOSVersion
        self.supportedPlatforms = supportedPlatforms
        self.teamId = teamId
    }
}

// MARK: - Device Info

/// Device information for testing
public struct DeviceInfo: Codable, Sendable {
    public let udid: String
    public let name: String
    public let model: String
    public let platform: Platform
    public let osVersion: String
    public let isSimulator: Bool
    public let state: DeviceState
    
    public enum DeviceState: String, Codable, Sendable {
        case available
        case unavailable
        case busy
        case shutdown
        case booted
    }
    
    public init(
        udid: String,
        name: String,
        model: String,
        platform: Platform,
        osVersion: String,
        isSimulator: Bool,
        state: DeviceState
    ) {
        self.udid = udid
        self.name = name
        self.model = model
        self.platform = platform
        self.osVersion = osVersion
        self.isSimulator = isSimulator
        self.state = state
    }
}

// MARK: - Notification

/// Notification payload for CI events
public struct CINotification: Codable, Sendable {
    public let event: CIEvent
    public let project: String
    public let branch: String
    public let commit: String?
    public let buildNumber: Int?
    public let status: Status
    public let duration: TimeInterval?
    public let url: String?
    public let message: String?
    
    public enum CIEvent: String, Codable, Sendable {
        case buildStarted = "build_started"
        case buildCompleted = "build_completed"
        case buildFailed = "build_failed"
        case testStarted = "test_started"
        case testCompleted = "test_completed"
        case testFailed = "test_failed"
        case deployStarted = "deploy_started"
        case deployCompleted = "deploy_completed"
        case deployFailed = "deploy_failed"
    }
    
    public enum Status: String, Codable, Sendable {
        case success
        case failure
        case cancelled
        case inProgress = "in_progress"
    }
}
