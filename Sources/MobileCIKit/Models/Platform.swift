// Platform.swift
// MobileCIKit
//
// Platform definitions and configurations for mobile CI/CD operations.

import Foundation
import ArgumentParser

// MARK: - Platform Enumeration

/// Supported mobile platforms
public enum Platform: String, ExpressibleByArgument, CaseIterable, Codable, Sendable {
    case ios
    case android
    case flutter
    case reactNative = "react-native"
    case macos
    case watchos
    case tvos
    case visionos
    case multiplatform
    
    public static var allValueStrings: [String] {
        return allCases.map { $0.rawValue }
    }
    
    public var displayName: String {
        switch self {
        case .ios: return "iOS"
        case .android: return "Android"
        case .flutter: return "Flutter"
        case .reactNative: return "React Native"
        case .macos: return "macOS"
        case .watchos: return "watchOS"
        case .tvos: return "tvOS"
        case .visionos: return "visionOS"
        case .multiplatform: return "Multiplatform"
        }
    }
    
    public var buildTool: String {
        switch self {
        case .ios, .macos, .watchos, .tvos, .visionos:
            return "xcodebuild"
        case .android:
            return "gradle"
        case .flutter:
            return "flutter"
        case .reactNative:
            return "npx react-native"
        case .multiplatform:
            return "varies"
        }
    }
    
    public var testTool: String {
        switch self {
        case .ios, .macos, .watchos, .tvos, .visionos:
            return "xcodebuild test"
        case .android:
            return "gradle test"
        case .flutter:
            return "flutter test"
        case .reactNative:
            return "jest"
        case .multiplatform:
            return "varies"
        }
    }
    
    public var packageManagers: [PackageManager] {
        switch self {
        case .ios, .macos, .watchos, .tvos, .visionos:
            return [.spm, .cocoapods, .carthage]
        case .android:
            return [.gradle, .maven]
        case .flutter:
            return [.pub]
        case .reactNative:
            return [.npm, .yarn, .pnpm]
        case .multiplatform:
            return PackageManager.allCases
        }
    }
    
    public var simulatorType: SimulatorType? {
        switch self {
        case .ios: return .iphone
        case .watchos: return .watch
        case .tvos: return .tv
        case .visionos: return .vision
        case .android: return .androidEmulator
        case .macos, .flutter, .reactNative, .multiplatform: return nil
        }
    }
    
    public var defaultXcodeDestination: String? {
        switch self {
        case .ios:
            return "platform=iOS Simulator,name=iPhone 15 Pro"
        case .watchos:
            return "platform=watchOS Simulator,name=Apple Watch Series 9 (45mm)"
        case .tvos:
            return "platform=tvOS Simulator,name=Apple TV 4K (3rd generation)"
        case .visionos:
            return "platform=visionOS Simulator,name=Apple Vision Pro"
        case .macos:
            return "platform=macOS"
        default:
            return nil
        }
    }
}

// MARK: - Package Manager

/// Supported package managers
public enum PackageManager: String, CaseIterable, Codable, Sendable {
    case spm = "Swift Package Manager"
    case cocoapods = "CocoaPods"
    case carthage = "Carthage"
    case gradle = "Gradle"
    case maven = "Maven"
    case pub = "Pub"
    case npm = "npm"
    case yarn = "Yarn"
    case pnpm = "pnpm"
    
    public var installCommand: String {
        switch self {
        case .spm: return "swift package resolve"
        case .cocoapods: return "pod install"
        case .carthage: return "carthage bootstrap --use-xcframeworks"
        case .gradle: return "./gradlew dependencies"
        case .maven: return "mvn dependency:resolve"
        case .pub: return "flutter pub get"
        case .npm: return "npm ci"
        case .yarn: return "yarn install --frozen-lockfile"
        case .pnpm: return "pnpm install --frozen-lockfile"
        }
    }
    
    public var lockFile: String {
        switch self {
        case .spm: return "Package.resolved"
        case .cocoapods: return "Podfile.lock"
        case .carthage: return "Cartfile.resolved"
        case .gradle: return "gradle.lockfile"
        case .maven: return "pom.xml"
        case .pub: return "pubspec.lock"
        case .npm: return "package-lock.json"
        case .yarn: return "yarn.lock"
        case .pnpm: return "pnpm-lock.yaml"
        }
    }
    
    public var cacheDirectory: String {
        switch self {
        case .spm: return ".build"
        case .cocoapods: return "Pods"
        case .carthage: return "Carthage"
        case .gradle: return ".gradle"
        case .maven: return ".m2"
        case .pub: return ".pub-cache"
        case .npm: return "node_modules"
        case .yarn: return "node_modules"
        case .pnpm: return "node_modules"
        }
    }
}

// MARK: - Simulator Type

/// Types of simulators/emulators
public enum SimulatorType: String, CaseIterable, Codable, Sendable {
    case iphone
    case ipad
    case watch
    case tv
    case vision
    case androidEmulator
    case androidDevice
    
    public var xcrunType: String? {
        switch self {
        case .iphone: return "iOS"
        case .ipad: return "iOS"
        case .watch: return "watchOS"
        case .tv: return "tvOS"
        case .vision: return "visionOS"
        default: return nil
        }
    }
}

// MARK: - Build Configuration

/// Build configuration options
public enum BuildConfiguration: String, ExpressibleByArgument, CaseIterable, Codable, Sendable {
    case debug
    case release
    case profile
    case staging
    case production
    
    public static var allValueStrings: [String] {
        return allCases.map { $0.rawValue }
    }
    
    public var xcodeBuildConfiguration: String {
        switch self {
        case .debug: return "Debug"
        case .release, .production: return "Release"
        case .profile: return "Profile"
        case .staging: return "Staging"
        }
    }
    
    public var gradleBuildType: String {
        switch self {
        case .debug: return "debug"
        case .release, .production: return "release"
        case .profile: return "profile"
        case .staging: return "staging"
        }
    }
    
    public var flutterMode: String {
        switch self {
        case .debug: return "--debug"
        case .release, .production: return "--release"
        case .profile: return "--profile"
        case .staging: return "--release"
        }
    }
}

// MARK: - Architecture

/// Target architectures
public enum Architecture: String, ExpressibleByArgument, CaseIterable, Codable, Sendable {
    case arm64
    case x86_64
    case armv7
    case armv7s
    case i386
    case universal
    
    public static var allValueStrings: [String] {
        return allCases.map { $0.rawValue }
    }
    
    public var isSimulator: Bool {
        switch self {
        case .x86_64, .i386: return true
        default: return false
        }
    }
    
    public var validPlatforms: [Platform] {
        switch self {
        case .arm64: return [.ios, .android, .macos, .watchos, .tvos, .visionos]
        case .x86_64: return [.ios, .macos, .tvos]
        case .armv7, .armv7s: return [.android]
        case .i386: return [.ios]
        case .universal: return [.ios, .macos]
        }
    }
}

// MARK: - Code Signing

/// Code signing configuration
public struct CodeSigningConfig: Codable, Sendable {
    public let identity: String?
    public let provisioningProfile: String?
    public let provisioningProfileSpecifier: String?
    public let teamId: String?
    public let signingStyle: SigningStyle
    public let entitlements: String?
    public let keychainPath: String?
    public let keychainPassword: String?
    
    public init(
        identity: String? = nil,
        provisioningProfile: String? = nil,
        provisioningProfileSpecifier: String? = nil,
        teamId: String? = nil,
        signingStyle: SigningStyle = .automatic,
        entitlements: String? = nil,
        keychainPath: String? = nil,
        keychainPassword: String? = nil
    ) {
        self.identity = identity
        self.provisioningProfile = provisioningProfile
        self.provisioningProfileSpecifier = provisioningProfileSpecifier
        self.teamId = teamId
        self.signingStyle = signingStyle
        self.entitlements = entitlements
        self.keychainPath = keychainPath
        self.keychainPassword = keychainPassword
    }
    
    public var xcodeBuildArgs: [String] {
        var args: [String] = []
        
        if let identity = identity {
            args.append("CODE_SIGN_IDENTITY=\(identity)")
        }
        
        if let profile = provisioningProfile {
            args.append("PROVISIONING_PROFILE=\(profile)")
        }
        
        if let specifier = provisioningProfileSpecifier {
            args.append("PROVISIONING_PROFILE_SPECIFIER=\(specifier)")
        }
        
        if let teamId = teamId {
            args.append("DEVELOPMENT_TEAM=\(teamId)")
        }
        
        switch signingStyle {
        case .automatic:
            args.append("CODE_SIGN_STYLE=Automatic")
        case .manual:
            args.append("CODE_SIGN_STYLE=Manual")
        }
        
        if let entitlements = entitlements {
            args.append("CODE_SIGN_ENTITLEMENTS=\(entitlements)")
        }
        
        return args
    }
}

/// Code signing style
public enum SigningStyle: String, Codable, Sendable {
    case automatic
    case manual
}

// MARK: - Export Options

/// Export options for iOS builds
public struct ExportOptions: Codable, Sendable {
    public let method: ExportMethod
    public let teamId: String?
    public let provisioningProfiles: [String: String]?
    public let signingCertificate: String?
    public let signingStyle: SigningStyle
    public let uploadBitcode: Bool
    public let uploadSymbols: Bool
    public let compileBitcode: Bool
    public let thinning: String?
    public let embedOnDemandResourcesAssetPacksInBundle: Bool
    public let iCloudContainerEnvironment: String?
    public let manifest: ManifestOptions?
    
    public init(
        method: ExportMethod = .appStore,
        teamId: String? = nil,
        provisioningProfiles: [String: String]? = nil,
        signingCertificate: String? = nil,
        signingStyle: SigningStyle = .automatic,
        uploadBitcode: Bool = true,
        uploadSymbols: Bool = true,
        compileBitcode: Bool = true,
        thinning: String? = nil,
        embedOnDemandResourcesAssetPacksInBundle: Bool = true,
        iCloudContainerEnvironment: String? = nil,
        manifest: ManifestOptions? = nil
    ) {
        self.method = method
        self.teamId = teamId
        self.provisioningProfiles = provisioningProfiles
        self.signingCertificate = signingCertificate
        self.signingStyle = signingStyle
        self.uploadBitcode = uploadBitcode
        self.uploadSymbols = uploadSymbols
        self.compileBitcode = compileBitcode
        self.thinning = thinning
        self.embedOnDemandResourcesAssetPacksInBundle = embedOnDemandResourcesAssetPacksInBundle
        self.iCloudContainerEnvironment = iCloudContainerEnvironment
        self.manifest = manifest
    }
    
    public func toPlist() -> String {
        var dict: [String: Any] = [
            "method": method.rawValue,
            "uploadBitcode": uploadBitcode,
            "uploadSymbols": uploadSymbols,
            "compileBitcode": compileBitcode,
            "embedOnDemandResourcesAssetPacksInBundle": embedOnDemandResourcesAssetPacksInBundle,
            "signingStyle": signingStyle.rawValue
        ]
        
        if let teamId = teamId {
            dict["teamID"] = teamId
        }
        
        if let profiles = provisioningProfiles {
            dict["provisioningProfiles"] = profiles
        }
        
        if let cert = signingCertificate {
            dict["signingCertificate"] = cert
        }
        
        if let thinning = thinning {
            dict["thinning"] = thinning
        }
        
        if let env = iCloudContainerEnvironment {
            dict["iCloudContainerEnvironment"] = env
        }
        
        return generatePlistString(from: dict)
    }
    
    private func generatePlistString(from dict: [String: Any]) -> String {
        var plist = """
        <?xml version="1.0" encoding="UTF-8"?>
        <!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
        <plist version="1.0">
        <dict>
        """
        
        for (key, value) in dict.sorted(by: { $0.key < $1.key }) {
            plist += "\n    <key>\(key)</key>"
            switch value {
            case let boolValue as Bool:
                plist += boolValue ? "\n    <true/>" : "\n    <false/>"
            case let stringValue as String:
                plist += "\n    <string>\(stringValue)</string>"
            case let dictValue as [String: String]:
                plist += "\n    <dict>"
                for (k, v) in dictValue.sorted(by: { $0.key < $1.key }) {
                    plist += "\n        <key>\(k)</key>"
                    plist += "\n        <string>\(v)</string>"
                }
                plist += "\n    </dict>"
            default:
                break
            }
        }
        
        plist += "\n</dict>\n</plist>"
        return plist
    }
}

/// Export methods for iOS builds
public enum ExportMethod: String, Codable, Sendable, CaseIterable {
    case appStore = "app-store"
    case adHoc = "ad-hoc"
    case enterprise = "enterprise"
    case development = "development"
    case validation = "validation"
    case package = "package"
    case developerIdApplication = "developer-id"
    case macApplication = "mac-application"
}

/// Manifest options for over-the-air distribution
public struct ManifestOptions: Codable, Sendable {
    public let appURL: String
    public let displayImageURL: String
    public let fullSizeImageURL: String
    public let assetPackManifestURL: String?
    
    public init(
        appURL: String,
        displayImageURL: String,
        fullSizeImageURL: String,
        assetPackManifestURL: String? = nil
    ) {
        self.appURL = appURL
        self.displayImageURL = displayImageURL
        self.fullSizeImageURL = fullSizeImageURL
        self.assetPackManifestURL = assetPackManifestURL
    }
}

// MARK: - Device

/// Represents a device or simulator
public struct Device: Codable, Sendable, Identifiable {
    public let id: String
    public let name: String
    public let platform: Platform
    public let osVersion: String
    public let isSimulator: Bool
    public let state: DeviceState
    public let architecture: Architecture
    
    public enum DeviceState: String, Codable, Sendable {
        case connected
        case booted
        case shutdown
        case unknown
    }
    
    public init(
        id: String,
        name: String,
        platform: Platform,
        osVersion: String,
        isSimulator: Bool,
        state: DeviceState,
        architecture: Architecture
    ) {
        self.id = id
        self.name = name
        self.platform = platform
        self.osVersion = osVersion
        self.isSimulator = isSimulator
        self.state = state
        self.architecture = architecture
    }
}

// MARK: - Test Target

/// Represents a test target configuration
public struct TestTarget: Codable, Sendable {
    public let name: String
    public let type: TestType
    public let platform: Platform
    public let scheme: String?
    public let testPlan: String?
    public let destination: String?
    public let parallel: Bool
    public let skipTests: [String]
    public let onlyTests: [String]
    public let codeCoverage: Bool
    public let resultBundlePath: String?
    public let environmentVariables: [String: String]
    public let arguments: [String]
    
    public enum TestType: String, Codable, Sendable {
        case unit
        case ui
        case integration
        case performance
        case snapshot
        case e2e
    }
    
    public init(
        name: String,
        type: TestType = .unit,
        platform: Platform = .ios,
        scheme: String? = nil,
        testPlan: String? = nil,
        destination: String? = nil,
        parallel: Bool = true,
        skipTests: [String] = [],
        onlyTests: [String] = [],
        codeCoverage: Bool = true,
        resultBundlePath: String? = nil,
        environmentVariables: [String: String] = [:],
        arguments: [String] = []
    ) {
        self.name = name
        self.type = type
        self.platform = platform
        self.scheme = scheme
        self.testPlan = testPlan
        self.destination = destination
        self.parallel = parallel
        self.skipTests = skipTests
        self.onlyTests = onlyTests
        self.codeCoverage = codeCoverage
        self.resultBundlePath = resultBundlePath
        self.environmentVariables = environmentVariables
        self.arguments = arguments
    }
}

// MARK: - Build Result

/// Result of a build operation
public struct BuildResult: Codable, Sendable {
    public let success: Bool
    public let platform: Platform
    public let configuration: BuildConfiguration
    public let artifactPath: String?
    public let artifactSize: Int64?
    public let duration: TimeInterval
    public let startTime: Date
    public let endTime: Date
    public let warnings: [BuildMessage]
    public let errors: [BuildMessage]
    public let buildSettings: [String: String]
    public let codeSigningInfo: CodeSigningInfo?
    
    public struct BuildMessage: Codable, Sendable {
        public let message: String
        public let file: String?
        public let line: Int?
        public let column: Int?
        public let severity: Severity
        
        public enum Severity: String, Codable, Sendable {
            case warning
            case error
            case note
        }
    }
    
    public struct CodeSigningInfo: Codable, Sendable {
        public let identity: String
        public let teamId: String
        public let provisioningProfile: String?
        public let certificateExpiry: Date?
    }
    
    public init(
        success: Bool,
        platform: Platform,
        configuration: BuildConfiguration,
        artifactPath: String? = nil,
        artifactSize: Int64? = nil,
        duration: TimeInterval,
        startTime: Date,
        endTime: Date,
        warnings: [BuildMessage] = [],
        errors: [BuildMessage] = [],
        buildSettings: [String: String] = [:],
        codeSigningInfo: CodeSigningInfo? = nil
    ) {
        self.success = success
        self.platform = platform
        self.configuration = configuration
        self.artifactPath = artifactPath
        self.artifactSize = artifactSize
        self.duration = duration
        self.startTime = startTime
        self.endTime = endTime
        self.warnings = warnings
        self.errors = errors
        self.buildSettings = buildSettings
        self.codeSigningInfo = codeSigningInfo
    }
}

// MARK: - Test Result

/// Result of a test run
public struct TestResult: Codable, Sendable {
    public let success: Bool
    public let totalTests: Int
    public let passedTests: Int
    public let failedTests: Int
    public let skippedTests: Int
    public let duration: TimeInterval
    public let testSuites: [TestSuite]
    public let codeCoverage: CodeCoverage?
    public let resultBundlePath: String?
    
    public struct TestSuite: Codable, Sendable {
        public let name: String
        public let tests: [TestCase]
        public let duration: TimeInterval
    }
    
    public struct TestCase: Codable, Sendable {
        public let name: String
        public let className: String
        public let status: Status
        public let duration: TimeInterval
        public let failureMessage: String?
        public let failureLocation: String?
        
        public enum Status: String, Codable, Sendable {
            case passed
            case failed
            case skipped
            case expectedFailure
        }
    }
    
    public struct CodeCoverage: Codable, Sendable {
        public let lineCoverage: Double
        public let branchCoverage: Double?
        public let functionCoverage: Double?
        public let files: [FileCoverage]
        
        public struct FileCoverage: Codable, Sendable {
            public let path: String
            public let lineCoverage: Double
            public let coveredLines: Int
            public let executableLines: Int
        }
    }
    
    public init(
        success: Bool,
        totalTests: Int,
        passedTests: Int,
        failedTests: Int,
        skippedTests: Int,
        duration: TimeInterval,
        testSuites: [TestSuite],
        codeCoverage: CodeCoverage? = nil,
        resultBundlePath: String? = nil
    ) {
        self.success = success
        self.totalTests = totalTests
        self.passedTests = passedTests
        self.failedTests = failedTests
        self.skippedTests = skippedTests
        self.duration = duration
        self.testSuites = testSuites
        self.codeCoverage = codeCoverage
        self.resultBundlePath = resultBundlePath
    }
}
