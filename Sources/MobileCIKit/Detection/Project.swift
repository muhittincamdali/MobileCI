/// A project MobileCI found in a repository.
public struct DetectedProject: Sendable, Equatable {
    /// The folder of the project relative to the repository root; `.` for the root.
    public let directory: String
    public let kind: Kind

    public init(directory: String, kind: Kind) {
        self.directory = directory
        self.kind = kind
    }

    public enum Kind: Sendable, Equatable {
        case xcode(XcodeProject)
        case swiftPackage(SwiftPackage)
        case flutter(FlutterProject)
        case reactNative(ReactNativeProject)
    }

    /// `iOS app`, `Swift package`, `Flutter` or `React Native` (`Expo` for an Expo project).
    public var kindName: String {
        switch kind {
        case .xcode(let project): return project.platform == .macOS ? "macOS app" : "iOS app"
        case .swiftPackage: return "Swift package"
        case .flutter: return "Flutter"
        case .reactNative(let project): return project.isExpo ? "Expo" : "React Native"
        }
    }
}

/// An Xcode project, with the workspace that wraps it when there is one.
public struct XcodeProject: Sendable, Equatable {
    /// `App.xcodeproj`, relative to the project directory.
    public let projectFile: String
    /// `App.xcworkspace` when one exists next to the project, or will after `pod install`.
    public let workspaceFile: String?
    /// The shared schemes; Xcode creates unshared ones per user, and CI cannot see those.
    public let schemes: [XcodeScheme]
    public let platform: ApplePlatform
    public let usesCocoaPods: Bool
    /// A `Gemfile` next to the `Podfile`: CocoaPods is run through Bundler.
    public let usesBundler: Bool
    public let usesSwiftPackages: Bool

    public init(projectFile: String, workspaceFile: String?, schemes: [XcodeScheme], platform: ApplePlatform,
                usesCocoaPods: Bool, usesBundler: Bool, usesSwiftPackages: Bool) {
        self.projectFile = projectFile
        self.workspaceFile = workspaceFile
        self.schemes = schemes
        self.platform = platform
        self.usesCocoaPods = usesCocoaPods
        self.usesBundler = usesBundler
        self.usesSwiftPackages = usesSwiftPackages
    }

    /// The scheme a workflow should build: the one named like the project, else the first one
    /// with tests, else the first one.
    public var defaultScheme: XcodeScheme? {
        let projectName = String(projectFile.dropLast(".xcodeproj".count))
        return schemes.first { $0.name == projectName } ?? schemes.first { $0.hasTests } ?? schemes.first
    }
}

/// A shared Xcode scheme.
public struct XcodeScheme: Sendable, Equatable {
    public let name: String
    /// Whether the scheme's test action lists a test target or a test plan.
    public let hasTests: Bool

    public init(name: String, hasTests: Bool) {
        self.name = name
        self.hasTests = hasTests
    }
}

public enum ApplePlatform: String, Sendable, Equatable {
    case iOS
    case macOS
}

public struct SwiftPackage: Sendable, Equatable {
    public let name: String?
    public let hasTests: Bool

    public init(name: String?, hasTests: Bool) {
        self.name = name
        self.hasTests = hasTests
    }
}

public struct FlutterProject: Sendable, Equatable {
    public let name: String?
    /// Platform folders present: `android`, `ios`, `web`, `macos`, `linux`, `windows`.
    public let platforms: Set<String>
    /// `environment: flutter:` when it is an exact version such as `3.47.8`, which
    /// `subosito/flutter-action` can read with `flutter-version-file`.
    public let pinnedFlutterVersion: String?
    /// `.fvmrc`, which `flutter-version-file` also reads.
    public let hasFVMConfig: Bool
    public let hasTests: Bool

    public init(name: String?, platforms: Set<String>, pinnedFlutterVersion: String?, hasFVMConfig: Bool, hasTests: Bool) {
        self.name = name
        self.platforms = platforms
        self.pinnedFlutterVersion = pinnedFlutterVersion
        self.hasFVMConfig = hasFVMConfig
        self.hasTests = hasTests
    }
}

public enum PackageManager: String, Sendable, Equatable {
    case npm
    case yarnClassic = "yarn"
    case yarnBerry = "yarn-berry"
    case pnpm
    case bun
}

public struct ReactNativeProject: Sendable, Equatable {
    public let name: String?
    public let isExpo: Bool
    public let packageManager: PackageManager
    /// Script names from `package.json` that a workflow runs when present.
    public let scripts: Set<String>
    /// `.nvmrc` or `.node-version`, read by `actions/setup-node`.
    public let nodeVersionFile: String?
    /// The native iOS project under `ios/`, when the project has one.
    public let iOS: XcodeProject?
    public let hasAndroid: Bool
    /// A `Gemfile` in the project root (the React Native template pins CocoaPods there).
    public let usesBundlerForPods: Bool

    public init(name: String?, isExpo: Bool, packageManager: PackageManager, scripts: Set<String>,
                nodeVersionFile: String?, iOS: XcodeProject?, hasAndroid: Bool, usesBundlerForPods: Bool) {
        self.name = name
        self.isExpo = isExpo
        self.packageManager = packageManager
        self.scripts = scripts
        self.nodeVersionFile = nodeVersionFile
        self.iOS = iOS
        self.hasAndroid = hasAndroid
        self.usesBundlerForPods = usesBundlerForPods
    }
}

/// Something a beginner should know before the first CI run.
public struct DetectionNote: Sendable, Equatable {
    public let directory: String
    public let severity: Severity
    public let message: String
}

/// Everything ``ProjectDetector`` found.
public struct DetectionReport: Sendable, Equatable {
    public let projects: [DetectedProject]
    public let notes: [DetectionNote]
}
