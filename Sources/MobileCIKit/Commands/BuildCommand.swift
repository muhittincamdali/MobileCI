// BuildCommand.swift
// MobileCIKit
//
// Build command implementation for mobile applications.

import Foundation
import ArgumentParser

/// Command for building mobile applications
public struct BuildCommand: AsyncParsableCommand {
    public static let configuration = CommandConfiguration(
        commandName: "build",
        abstract: "Build mobile applications for various platforms",
        discussion: """
            Build iOS, Android, Flutter, or React Native applications with full
            support for code signing, caching, and artifact generation.
            
            EXAMPLES:
              mobileci build --platform ios --scheme MyApp
              mobileci build --platform flutter --release
              mobileci build --platform android --flavor production
              mobileci build --platform ios --archive --export-method app-store
            """
    )
    
    // MARK: - Options
    
    @Option(name: .shortAndLong, help: "Target platform (ios, android, flutter, react-native)")
    var platform: Platform = .ios
    
    @Option(name: .long, help: "Build configuration (debug, release, staging, production)")
    var configuration: BuildConfiguration = .release
    
    @Option(name: .long, help: "Xcode scheme to build")
    var scheme: String?
    
    @Option(name: .long, help: "Xcode project file (.xcodeproj)")
    var project: String?
    
    @Option(name: .long, help: "Xcode workspace file (.xcworkspace)")
    var workspace: String?
    
    @Option(name: .long, help: "Swift package path")
    var package: String?
    
    @Option(name: .long, help: "Build target")
    var target: String?
    
    @Option(name: .long, help: "Build destination")
    var destination: String?
    
    @Option(name: .long, help: "Output directory for build artifacts")
    var output: String?
    
    @Option(name: .long, help: "Derived data path")
    var derivedDataPath: String?
    
    @Option(name: .long, help: "Archive path for iOS builds")
    var archivePath: String?
    
    @Option(name: .long, help: "Export method (app-store, ad-hoc, enterprise, development)")
    var exportMethod: ExportMethod?
    
    @Option(name: .long, help: "Export options plist path")
    var exportOptionsPlist: String?
    
    @Option(name: .long, help: "Team ID for code signing")
    var teamId: String?
    
    @Option(name: .long, help: "Code signing identity")
    var signingIdentity: String?
    
    @Option(name: .long, help: "Provisioning profile name or UUID")
    var provisioningProfile: String?
    
    @Option(name: .long, help: "Android build flavor")
    var flavor: String?
    
    @Option(name: .long, help: "Android build type")
    var buildType: String?
    
    @Option(name: .long, help: "Flutter build target file")
    var flutterTarget: String?
    
    @Option(name: .long, help: "Build number override")
    var buildNumber: String?
    
    @Option(name: .long, help: "Version string override")
    var version: String?
    
    @Option(name: .long, help: "Additional build arguments", parsing: .upToNextOption)
    var buildArgs: [String] = []
    
    @Option(name: .long, help: "Maximum parallel jobs")
    var jobs: Int?
    
    @Option(name: .long, help: "Build timeout in seconds")
    var timeout: Int?
    
    // MARK: - Flags
    
    @Flag(name: .long, help: "Create an archive (iOS)")
    var archive: Bool = false
    
    @Flag(name: .long, help: "Export the archive to IPA (iOS)")
    var export: Bool = false
    
    @Flag(name: .long, help: "Clean before building")
    var clean: Bool = false
    
    @Flag(name: .long, help: "Build for simulator only")
    var simulator: Bool = false
    
    @Flag(name: .long, help: "Build for device only")
    var device: Bool = false
    
    @Flag(name: .long, help: "Generate dSYM files")
    var dsym: Bool = true
    
    @Flag(name: .long, help: "Enable bitcode")
    var bitcode: Bool = false
    
    @Flag(name: .long, help: "Enable testability")
    var testability: Bool = false
    
    @Flag(name: .long, help: "Use xcpretty for output formatting")
    var xcpretty: Bool = true
    
    @Flag(name: .long, help: "Skip code signing")
    var skipSigning: Bool = false
    
    @Flag(name: .long, help: "Skip dependency installation")
    var skipDependencies: Bool = false
    
    @Flag(name: .long, help: "Build for all architectures")
    var universal: Bool = false
    
    @Flag(name: .shortAndLong, help: "Enable verbose output")
    var verbose: Bool = false
    
    @Flag(name: .long, help: "Dry run - show commands without executing")
    var dryRun: Bool = false
    
    public init() {}
    
    // MARK: - Execution
    
    public func run() async throws {
        let startTime = Date()
        let logger = Logger.shared
        
        if verbose {
            logger.setMinimumLevel(.debug)
        }
        
        logger.info("Starting build for \(platform.displayName)...")
        
        // Detect project if not specified
        let projectInfo = try await detectProject()
        
        // Install dependencies if needed
        if !skipDependencies {
            try await installDependencies(projectInfo: projectInfo)
        }
        
        // Execute build based on platform
        let result: BuildResult
        
        switch platform {
        case .ios, .macos, .watchos, .tvos, .visionos:
            result = try await buildApplePlatform(projectInfo: projectInfo)
        case .android:
            result = try await buildAndroid(projectInfo: projectInfo)
        case .flutter:
            result = try await buildFlutter(projectInfo: projectInfo)
        case .reactNative:
            result = try await buildReactNative(projectInfo: projectInfo)
        case .multiplatform:
            result = try await buildMultiplatform(projectInfo: projectInfo)
        }
        
        // Report results
        let duration = Date().timeIntervalSince(startTime)
        reportBuildResult(result, duration: duration)
    }
    
    // MARK: - Project Detection
    
    private struct ProjectInfo {
        let project: String?
        let workspace: String?
        let scheme: String?
        let target: String?
        let packagePath: String?
        let packageManagers: [PackageManager]
    }
    
    private func detectProject() async throws -> ProjectInfo {
        let fileManager = FileManager.default
        let currentDir = fileManager.currentDirectoryPath
        
        var detectedProject: String?
        var detectedWorkspace: String?
        var detectedScheme = scheme
        var detectedTarget = target
        var detectedPackage: String?
        var packageManagers: [PackageManager] = []
        
        // Check for explicit values first
        if let project = project {
            detectedProject = project
        }
        if let workspace = workspace {
            detectedWorkspace = workspace
        }
        if let package = package {
            detectedPackage = package
        }
        
        // Auto-detect if not specified
        if detectedProject == nil && detectedWorkspace == nil && detectedPackage == nil {
            let contents = try fileManager.contentsOfDirectory(atPath: currentDir)
            
            // Look for workspace first
            if let workspaceFile = contents.first(where: { $0.hasSuffix(".xcworkspace") }) {
                detectedWorkspace = workspaceFile
                Logger.shared.debug("Detected workspace: \(workspaceFile)")
            }
            
            // Look for project
            if let projectFile = contents.first(where: { $0.hasSuffix(".xcodeproj") }) {
                detectedProject = projectFile
                Logger.shared.debug("Detected project: \(projectFile)")
            }
            
            // Look for Package.swift
            if contents.contains("Package.swift") {
                detectedPackage = "."
                Logger.shared.debug("Detected Swift package")
            }
        }
        
        // Detect package managers
        let contents = try fileManager.contentsOfDirectory(atPath: currentDir)
        
        if contents.contains("Podfile") {
            packageManagers.append(.cocoapods)
        }
        if contents.contains("Cartfile") {
            packageManagers.append(.carthage)
        }
        if contents.contains("Package.swift") || contents.contains("Package.resolved") {
            packageManagers.append(.spm)
        }
        if contents.contains("build.gradle") || contents.contains("build.gradle.kts") {
            packageManagers.append(.gradle)
        }
        if contents.contains("pubspec.yaml") {
            packageManagers.append(.pub)
        }
        if contents.contains("package.json") {
            if contents.contains("yarn.lock") {
                packageManagers.append(.yarn)
            } else if contents.contains("pnpm-lock.yaml") {
                packageManagers.append(.pnpm)
            } else {
                packageManagers.append(.npm)
            }
        }
        
        // Auto-detect scheme if not specified
        if detectedScheme == nil {
            if let workspace = detectedWorkspace ?? detectedProject {
                detectedScheme = try await detectScheme(from: workspace)
            }
        }
        
        return ProjectInfo(
            project: detectedProject,
            workspace: detectedWorkspace,
            scheme: detectedScheme,
            target: detectedTarget,
            packagePath: detectedPackage,
            packageManagers: packageManagers
        )
    }
    
    private func detectScheme(from projectOrWorkspace: String) async throws -> String? {
        let isWorkspace = projectOrWorkspace.hasSuffix(".xcworkspace")
        let flag = isWorkspace ? "-workspace" : "-project"
        
        let result = try ProcessRunner.shared.run(
            "xcodebuild \(flag) \"\(projectOrWorkspace)\" -list -json"
        )
        
        guard result.success else {
            return nil
        }
        
        guard let data = result.stdout.data(using: .utf8),
              let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let projectInfo = json["project"] as? [String: Any] ?? json["workspace"] as? [String: Any],
              let schemes = projectInfo["schemes"] as? [String],
              let firstScheme = schemes.first else {
            return nil
        }
        
        Logger.shared.debug("Detected scheme: \(firstScheme)")
        return firstScheme
    }
    
    // MARK: - Dependencies
    
    private func installDependencies(projectInfo: ProjectInfo) async throws {
        let logger = Logger.shared
        
        for manager in projectInfo.packageManagers {
            logger.info("Installing dependencies with \(manager.rawValue)...")
            
            let spinner = logger.spinner("Installing \(manager.rawValue) dependencies")
            spinner.start()
            
            do {
                if dryRun {
                    logger.debug("[DRY RUN] Would execute: \(manager.installCommand)")
                } else {
                    let result = try ProcessRunner.shared.run(manager.installCommand, options: .default.with(printOutput: verbose))
                    if !result.success {
                        spinner.stop(success: false)
                        throw BuildError.dependencyInstallationFailed(manager: manager.rawValue, message: result.stderr)
                    }
                }
                spinner.stop(success: true)
            } catch {
                spinner.stop(success: false)
                throw error
            }
        }
    }
    
    // MARK: - Apple Platform Build
    
    private func buildApplePlatform(projectInfo: ProjectInfo) async throws -> BuildResult {
        let logger = Logger.shared
        let startTime = Date()
        
        var args: [String] = []
        
        // Project/Workspace/Package
        if let workspace = projectInfo.workspace {
            args.append("-workspace \"\(workspace)\"")
        } else if let project = projectInfo.project {
            args.append("-project \"\(project)\"")
        } else if let packagePath = projectInfo.packagePath {
            args.append("-package-path \"\(packagePath)\"")
        }
        
        // Scheme/Target
        if let scheme = projectInfo.scheme ?? scheme {
            args.append("-scheme \"\(scheme)\"")
        } else if let target = projectInfo.target ?? target {
            args.append("-target \"\(target)\"")
        }
        
        // Configuration
        args.append("-configuration \(configuration.xcodeBuildConfiguration)")
        
        // Destination
        if let destination = destination {
            args.append("-destination \"\(destination)\"")
        } else if simulator {
            if let defaultDest = platform.defaultXcodeDestination {
                args.append("-destination \"\(defaultDest)\"")
            }
        } else if device {
            args.append("-destination generic/platform=iOS")
        }
        
        // Derived data
        if let derivedDataPath = derivedDataPath {
            args.append("-derivedDataPath \"\(derivedDataPath)\"")
        }
        
        // Build settings
        if let teamId = teamId {
            args.append("DEVELOPMENT_TEAM=\(teamId)")
        }
        
        if skipSigning {
            args.append("CODE_SIGNING_ALLOWED=NO")
            args.append("CODE_SIGN_IDENTITY=\"\"")
        } else {
            if let identity = signingIdentity {
                args.append("CODE_SIGN_IDENTITY=\"\(identity)\"")
            }
            if let profile = provisioningProfile {
                args.append("PROVISIONING_PROFILE_SPECIFIER=\"\(profile)\"")
            }
        }
        
        if dsym {
            args.append("DEBUG_INFORMATION_FORMAT=dwarf-with-dsym")
        }
        
        if bitcode {
            args.append("ENABLE_BITCODE=YES")
        } else {
            args.append("ENABLE_BITCODE=NO")
        }
        
        if testability {
            args.append("ENABLE_TESTABILITY=YES")
        }
        
        if let buildNumber = buildNumber {
            args.append("CURRENT_PROJECT_VERSION=\(buildNumber)")
        }
        
        if let version = version {
            args.append("MARKETING_VERSION=\(version)")
        }
        
        if let jobs = jobs {
            args.append("-jobs \(jobs)")
        }
        
        // Additional arguments
        args.append(contentsOf: buildArgs)
        
        // Determine action
        var action = "build"
        if archive {
            action = "archive"
            if let archivePath = archivePath {
                args.append("-archivePath \"\(archivePath)\"")
            } else {
                let archiveName = projectInfo.scheme ?? "App"
                args.append("-archivePath \"build/\(archiveName).xcarchive\"")
            }
        }
        
        if clean {
            action = "clean \(action)"
        }
        
        // Build command
        var command = "xcodebuild \(action) \(args.joined(separator: " "))"
        
        if xcpretty && !verbose {
            command += " | xcpretty"
        }
        
        logger.debug("Build command: \(command)")
        
        if dryRun {
            logger.info("[DRY RUN] Would execute build command")
            return BuildResult(
                success: true,
                platform: platform,
                configuration: configuration,
                duration: 0,
                startTime: startTime,
                endTime: Date()
            )
        }
        
        // Execute build
        let result = try ProcessRunner.shared.run(command, options: .default.with(printOutput: true))
        
        var artifactPath: String?
        
        // Export if needed
        if archive && export && result.success {
            artifactPath = try await exportArchive(projectInfo: projectInfo)
        }
        
        let endTime = Date()
        
        return BuildResult(
            success: result.success,
            platform: platform,
            configuration: configuration,
            artifactPath: artifactPath,
            duration: endTime.timeIntervalSince(startTime),
            startTime: startTime,
            endTime: endTime
        )
    }
    
    private func exportArchive(projectInfo: ProjectInfo) async throws -> String {
        let logger = Logger.shared
        logger.info("Exporting archive...")
        
        let archiveName = projectInfo.scheme ?? "App"
        let archivePathStr = archivePath ?? "build/\(archiveName).xcarchive"
        let exportPath = output ?? "build/export"
        
        var args = [
            "-exportArchive",
            "-archivePath \"\(archivePathStr)\"",
            "-exportPath \"\(exportPath)\""
        ]
        
        // Export options
        if let plist = exportOptionsPlist {
            args.append("-exportOptionsPlist \"\(plist)\"")
        } else if let method = exportMethod {
            // Generate export options plist
            let options = ExportOptions(
                method: method,
                teamId: teamId,
                signingStyle: skipSigning ? .manual : .automatic,
                uploadBitcode: bitcode,
                uploadSymbols: dsym
            )
            
            let plistPath = "build/ExportOptions.plist"
            try options.toPlist().write(toFile: plistPath, atomically: true, encoding: .utf8)
            args.append("-exportOptionsPlist \"\(plistPath)\"")
        }
        
        let command = "xcodebuild \(args.joined(separator: " "))"
        
        if dryRun {
            logger.info("[DRY RUN] Would execute export command")
            return exportPath
        }
        
        let result = try ProcessRunner.shared.run(command, options: .default.with(printOutput: verbose))
        
        guard result.success else {
            throw BuildError.exportFailed(message: result.stderr)
        }
        
        // Find IPA
        let fileManager = FileManager.default
        let exportURL = URL(fileURLWithPath: exportPath)
        
        if let contents = try? fileManager.contentsOfDirectory(atPath: exportPath),
           let ipa = contents.first(where: { $0.hasSuffix(".ipa") }) {
            return (exportURL.appendingPathComponent(ipa)).path
        }
        
        return exportPath
    }
    
    // MARK: - Android Build
    
    private func buildAndroid(projectInfo: ProjectInfo) async throws -> BuildResult {
        let logger = Logger.shared
        let startTime = Date()
        
        var gradleTask = "assemble"
        
        // Determine task
        let buildTypeName = buildType ?? configuration.gradleBuildType.capitalized
        
        if let flavor = flavor {
            gradleTask = "assemble\(flavor.capitalized)\(buildTypeName)"
        } else {
            gradleTask = "assemble\(buildTypeName)"
        }
        
        if clean {
            gradleTask = "clean \(gradleTask)"
        }
        
        var args: [String] = [gradleTask]
        
        if let jobs = jobs {
            args.append("--max-workers=\(jobs)")
        }
        
        if verbose {
            args.append("--info")
        }
        
        if let buildNumber = buildNumber {
            args.append("-PversionCode=\(buildNumber)")
        }
        
        if let version = version {
            args.append("-PversionName=\(version)")
        }
        
        args.append(contentsOf: buildArgs)
        
        let command = "./gradlew \(args.joined(separator: " "))"
        
        logger.debug("Build command: \(command)")
        
        if dryRun {
            logger.info("[DRY RUN] Would execute: \(command)")
            return BuildResult(
                success: true,
                platform: platform,
                configuration: configuration,
                duration: 0,
                startTime: startTime,
                endTime: Date()
            )
        }
        
        let result = try ProcessRunner.shared.run(command, options: .default.with(printOutput: true))
        
        let endTime = Date()
        
        // Find APK/AAB
        var artifactPath: String?
        let outputDir = "app/build/outputs"
        
        if let flavor = flavor {
            let apkPath = "\(outputDir)/apk/\(flavor)/\(buildType ?? "release")"
            if FileManager.default.fileExists(atPath: apkPath) {
                artifactPath = apkPath
            }
        } else {
            let apkPath = "\(outputDir)/apk/\(buildType ?? "release")"
            if FileManager.default.fileExists(atPath: apkPath) {
                artifactPath = apkPath
            }
        }
        
        return BuildResult(
            success: result.success,
            platform: platform,
            configuration: configuration,
            artifactPath: artifactPath,
            duration: endTime.timeIntervalSince(startTime),
            startTime: startTime,
            endTime: endTime
        )
    }
    
    // MARK: - Flutter Build
    
    private func buildFlutter(projectInfo: ProjectInfo) async throws -> BuildResult {
        let logger = Logger.shared
        let startTime = Date()
        
        // Determine build target
        var buildTarget: String
        
        switch platform {
        case .ios:
            buildTarget = archive ? "ipa" : "ios"
        case .android:
            buildTarget = "apk"
        default:
            buildTarget = "ios"
        }
        
        var args: [String] = ["build", buildTarget]
        
        // Build mode
        args.append(configuration.flutterMode)
        
        if let flutterTarget = flutterTarget {
            args.append("--target=\(flutterTarget)")
        }
        
        if let flavor = flavor {
            args.append("--flavor=\(flavor)")
        }
        
        if let buildNumber = buildNumber {
            args.append("--build-number=\(buildNumber)")
        }
        
        if let version = version {
            args.append("--build-name=\(version)")
        }
        
        if verbose {
            args.append("--verbose")
        }
        
        // iOS specific
        if buildTarget == "ios" || buildTarget == "ipa" {
            if simulator {
                args.append("--simulator")
            }
            
            if let exportMethod = exportMethod {
                args.append("--export-method=\(exportMethod.rawValue)")
            }
            
            if skipSigning {
                args.append("--no-codesign")
            }
        }
        
        // Android specific
        if buildTarget == "apk" || buildTarget == "appbundle" {
            if let buildType = buildType {
                if buildType == "release" {
                    args.append("--release")
                } else if buildType == "debug" {
                    args.append("--debug")
                }
            }
        }
        
        args.append(contentsOf: buildArgs)
        
        let command = "flutter \(args.joined(separator: " "))"
        
        logger.debug("Build command: \(command)")
        
        if dryRun {
            logger.info("[DRY RUN] Would execute: \(command)")
            return BuildResult(
                success: true,
                platform: platform,
                configuration: configuration,
                duration: 0,
                startTime: startTime,
                endTime: Date()
            )
        }
        
        // Clean if requested
        if clean {
            logger.info("Cleaning Flutter build...")
            _ = try? ProcessRunner.shared.run("flutter clean")
        }
        
        let result = try ProcessRunner.shared.run(command, options: .default.with(printOutput: true))
        
        let endTime = Date()
        
        // Find artifact
        var artifactPath: String?
        
        if buildTarget == "ios" || buildTarget == "ipa" {
            if archive {
                artifactPath = "build/ios/ipa"
            } else {
                artifactPath = "build/ios/iphoneos"
            }
        } else {
            artifactPath = "build/app/outputs/flutter-apk"
        }
        
        return BuildResult(
            success: result.success,
            platform: platform,
            configuration: configuration,
            artifactPath: artifactPath,
            duration: endTime.timeIntervalSince(startTime),
            startTime: startTime,
            endTime: endTime
        )
    }
    
    // MARK: - React Native Build
    
    private func buildReactNative(projectInfo: ProjectInfo) async throws -> BuildResult {
        let logger = Logger.shared
        let startTime = Date()
        
        // Install JS dependencies first
        if !skipDependencies {
            logger.info("Installing JavaScript dependencies...")
            
            let npmResult = try ProcessRunner.shared.run(
                projectInfo.packageManagers.contains(.yarn) ? "yarn install" : "npm ci",
                options: .default.with(printOutput: verbose)
            )
            
            if !npmResult.success {
                throw BuildError.dependencyInstallationFailed(manager: "npm/yarn", message: npmResult.stderr)
            }
        }
        
        var result: ProcessResult
        var artifactPath: String?
        
        // Build based on target platform
        if platform == .ios || platform == .reactNative {
            // Build iOS
            var args: [String] = []
            
            args.append("run-ios")
            
            if let scheme = scheme ?? projectInfo.scheme {
                args.append("--scheme \"\(scheme)\"")
            }
            
            if configuration == .release {
                args.append("--configuration Release")
            }
            
            if simulator {
                args.append("--simulator \"iPhone 15 Pro\"")
            } else if device {
                args.append("--device")
            }
            
            let command = "npx react-native \(args.joined(separator: " "))"
            
            logger.debug("Build command: \(command)")
            
            if dryRun {
                logger.info("[DRY RUN] Would execute: \(command)")
                return BuildResult(
                    success: true,
                    platform: platform,
                    configuration: configuration,
                    duration: 0,
                    startTime: startTime,
                    endTime: Date()
                )
            }
            
            // For release builds, use xcodebuild directly
            if configuration == .release || archive {
                let iosDir = "ios"
                let workspaceFiles = try FileManager.default.contentsOfDirectory(atPath: iosDir)
                    .filter { $0.hasSuffix(".xcworkspace") }
                
                if let workspace = workspaceFiles.first {
                    let projectInfo = ProjectInfo(
                        project: nil,
                        workspace: "\(iosDir)/\(workspace)",
                        scheme: scheme,
                        target: nil,
                        packagePath: nil,
                        packageManagers: []
                    )
                    return try await buildApplePlatform(projectInfo: projectInfo)
                }
            }
            
            result = try ProcessRunner.shared.run(command, options: .default.with(printOutput: true))
            artifactPath = "ios/build/Build/Products"
            
        } else {
            // Build Android
            let gradleTask = configuration == .release ? "assembleRelease" : "assembleDebug"
            let command = "cd android && ./gradlew \(gradleTask)"
            
            logger.debug("Build command: \(command)")
            
            if dryRun {
                logger.info("[DRY RUN] Would execute: \(command)")
                return BuildResult(
                    success: true,
                    platform: platform,
                    configuration: configuration,
                    duration: 0,
                    startTime: startTime,
                    endTime: Date()
                )
            }
            
            result = try ProcessRunner.shared.run(command, options: .default.with(printOutput: true))
            artifactPath = "android/app/build/outputs/apk"
        }
        
        let endTime = Date()
        
        return BuildResult(
            success: result.success,
            platform: platform,
            configuration: configuration,
            artifactPath: artifactPath,
            duration: endTime.timeIntervalSince(startTime),
            startTime: startTime,
            endTime: endTime
        )
    }
    
    // MARK: - Multiplatform Build
    
    private func buildMultiplatform(projectInfo: ProjectInfo) async throws -> BuildResult {
        let logger = Logger.shared
        let startTime = Date()
        
        logger.info("Building for multiple platforms...")
        
        var results: [BuildResult] = []
        
        // Determine which platforms to build
        var platformsToBuild: [Platform] = []
        
        if FileManager.default.fileExists(atPath: "ios") {
            platformsToBuild.append(.ios)
        }
        if FileManager.default.fileExists(atPath: "android") {
            platformsToBuild.append(.android)
        }
        
        for targetPlatform in platformsToBuild {
            logger.info("Building \(targetPlatform.displayName)...")
            
            var modifiedCommand = self
            modifiedCommand.platform = targetPlatform
            
            let result: BuildResult
            
            switch targetPlatform {
            case .ios:
                result = try await modifiedCommand.buildApplePlatform(projectInfo: projectInfo)
            case .android:
                result = try await modifiedCommand.buildAndroid(projectInfo: projectInfo)
            default:
                continue
            }
            
            results.append(result)
        }
        
        let endTime = Date()
        let allSuccessful = results.allSatisfy { $0.success }
        
        return BuildResult(
            success: allSuccessful,
            platform: .multiplatform,
            configuration: configuration,
            duration: endTime.timeIntervalSince(startTime),
            startTime: startTime,
            endTime: endTime
        )
    }
    
    // MARK: - Reporting
    
    private func reportBuildResult(_ result: BuildResult, duration: TimeInterval) {
        let logger = Logger.shared
        
        let formatter = DateComponentsFormatter()
        formatter.allowedUnits = [.minute, .second]
        formatter.unitsStyle = .abbreviated
        let durationString = formatter.string(from: duration) ?? "\(Int(duration))s"
        
        if result.success {
            logger.success("Build completed successfully in \(durationString)")
            
            if let artifactPath = result.artifactPath {
                logger.info("Artifact: \(artifactPath)")
                
                // Print artifact size if available
                if let attributes = try? FileManager.default.attributesOfItem(atPath: artifactPath),
                   let size = attributes[.size] as? Int64 {
                    let sizeString = ByteCountFormatter.string(fromByteCount: size, countStyle: .file)
                    logger.info("Size: \(sizeString)")
                }
            }
        } else {
            logger.error("Build failed after \(durationString)")
            
            for error in result.errors {
                logger.error("  \(error.message)")
                if let file = error.file, let line = error.line {
                    logger.error("    at \(file):\(line)")
                }
            }
        }
        
        // Print warnings
        if !result.warnings.isEmpty {
            logger.warning("\(result.warnings.count) warning(s)")
            if verbose {
                for warning in result.warnings.prefix(10) {
                    logger.warning("  \(warning.message)")
                }
                if result.warnings.count > 10 {
                    logger.warning("  ... and \(result.warnings.count - 10) more")
                }
            }
        }
    }
}

// MARK: - Build Errors

/// Errors that can occur during build
public enum BuildError: LocalizedError {
    case projectNotFound
    case schemeNotFound
    case dependencyInstallationFailed(manager: String, message: String)
    case buildFailed(message: String)
    case archiveFailed(message: String)
    case exportFailed(message: String)
    case signingFailed(message: String)
    case timeout
    
    public var errorDescription: String? {
        switch self {
        case .projectNotFound:
            return "No Xcode project or workspace found in the current directory"
        case .schemeNotFound:
            return "No build scheme found. Specify one with --scheme"
        case .dependencyInstallationFailed(let manager, let message):
            return "\(manager) dependency installation failed: \(message)"
        case .buildFailed(let message):
            return "Build failed: \(message)"
        case .archiveFailed(let message):
            return "Archive failed: \(message)"
        case .exportFailed(let message):
            return "Export failed: \(message)"
        case .signingFailed(let message):
            return "Code signing failed: \(message)"
        case .timeout:
            return "Build timed out"
        }
    }
}
