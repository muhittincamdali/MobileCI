// DeployCommand.swift
// MobileCIKit
//
// Deployment command for TestFlight, App Store, and other distribution targets.
// Handles build upload, release notes, and beta tester management.

import Foundation
import ArgumentParser

/// Command for deploying mobile applications
public struct DeployCommand: AsyncParsableCommand {
    public static let configuration = CommandConfiguration(
        commandName: "deploy",
        abstract: "Deploy applications to various distribution targets",
        discussion: """
            Deploy iOS apps to TestFlight, App Store, Firebase, or custom targets.
            Handles code signing, build upload, and release management.
            
            EXAMPLES:
              mobileci deploy --target testflight --ipa build/App.ipa
              mobileci deploy --target appstore --version 1.2.0
              mobileci deploy --target firebase --groups testers
              mobileci deploy --target appcenter --distribute
            """
    )
    
    // MARK: - Options
    
    @Option(name: .shortAndLong, help: "Deployment target (testflight, appstore, firebase, appcenter)")
    var target: DeployTarget = .testflight
    
    @Option(name: .long, help: "Path to IPA file")
    var ipa: String?
    
    @Option(name: .long, help: "Path to archive (.xcarchive)")
    var archive: String?
    
    @Option(name: .long, help: "App bundle ID")
    var bundleId: String?
    
    @Option(name: .long, help: "Version string for release")
    var version: String?
    
    @Option(name: .long, help: "Build number")
    var buildNumber: String?
    
    @Option(name: .long, help: "Release notes")
    var notes: String?
    
    @Option(name: .long, help: "Path to release notes file")
    var notesFile: String?
    
    @Option(name: .long, help: "Beta group names (comma-separated)")
    var groups: String?
    
    @Option(name: .long, help: "Tester emails (comma-separated)")
    var testers: String?
    
    @Option(name: .long, help: "Firebase App ID")
    var firebaseAppId: String?
    
    @Option(name: .long, help: "App Center app name")
    var appCenterApp: String?
    
    @Option(name: .long, help: "App Center owner name")
    var appCenterOwner: String?
    
    @Option(name: .long, help: "Export options plist path")
    var exportOptions: String?
    
    @Option(name: .long, help: "Team ID for code signing")
    var teamId: String?
    
    @Option(name: .long, help: "API key path for App Store Connect")
    var apiKey: String?
    
    @Option(name: .long, help: "App Store Connect API Key ID")
    var apiKeyId: String?
    
    @Option(name: .long, help: "App Store Connect Issuer ID")
    var apiIssuerId: String?
    
    @Option(name: .long, help: "Upload timeout in seconds")
    var timeout: Int = 3600
    
    // MARK: - Flags
    
    @Flag(name: .long, help: "Submit for beta review after upload")
    var submitBetaReview: Bool = false
    
    @Flag(name: .long, help: "Submit for App Store review after upload")
    var submitReview: Bool = false
    
    @Flag(name: .long, help: "Enable automatic release after review")
    var autoRelease: Bool = false
    
    @Flag(name: .long, help: "Skip build validation")
    var skipValidation: Bool = false
    
    @Flag(name: .long, help: "Distribute to all testers immediately")
    var distribute: Bool = false
    
    @Flag(name: .long, help: "Force upload even if version exists")
    var force: Bool = false
    
    @Flag(name: .long, help: "Generate changelog from git commits")
    var generateChangelog: Bool = false
    
    @Flag(name: .shortAndLong, help: "Verbose output")
    var verbose: Bool = false
    
    @Flag(name: .long, help: "Dry run - show actions without executing")
    var dryRun: Bool = false
    
    public init() {}
    
    // MARK: - Execution
    
    public func run() async throws {
        let logger = Logger.shared
        
        if verbose {
            logger.setMinimumLevel(.debug)
        }
        
        logger.info("Deploying to \(target.rawValue)...")
        
        // Get release notes
        let releaseNotes = try await getReleaseNotes()
        
        // Execute deployment based on target
        switch target {
        case .testflight:
            try await deployToTestFlight(releaseNotes: releaseNotes)
        case .appStore:
            try await deployToAppStore(releaseNotes: releaseNotes)
        case .firebase:
            try await deployToFirebase(releaseNotes: releaseNotes)
        case .appcenter:
            try await deployToAppCenter(releaseNotes: releaseNotes)
        case .playStore, .playStoreInternal:
            try await deployToPlayStore(releaseNotes: releaseNotes)
        case .s3:
            try await deployToS3()
        case .custom:
            logger.warning("Custom deployment requires manual configuration")
        }
    }
    
    // MARK: - Release Notes
    
    private func getReleaseNotes() async throws -> String {
        if let notes = notes {
            return notes
        }
        
        if let notesFile = notesFile {
            return try String(contentsOfFile: notesFile, encoding: .utf8)
        }
        
        if generateChangelog {
            let changelog = ChangelogGenerator.shared
            let latestTag = try? changelog.getLatestTag()
            
            let entry = try changelog.generateChangelog(
                version: version ?? "Current",
                from: latestTag,
                config: .init(
                    includeCommitHash: false,
                    includeAuthor: false,
                    useEmoji: true,
                    includedTypes: [.feat, .fix, .perf]
                ),
                format: .releaseNotes
            )
            
            return entry
        }
        
        return "Bug fixes and improvements"
    }
    
    // MARK: - TestFlight Deployment
    
    private func deployToTestFlight(releaseNotes: String) async throws {
        let logger = Logger.shared
        
        logger.info("Deploying to TestFlight...")
        
        // Get IPA path
        let ipaPath = try getIPAPath()
        
        logger.info("IPA: \(ipaPath)")
        logger.debug("Release notes: \(releaseNotes)")
        
        if dryRun {
            logger.info("[DRY RUN] Would upload to TestFlight")
            return
        }
        
        // Use altool or notarytool for upload
        let uploadCommand = try buildUploadCommand(ipaPath: ipaPath)
        
        logger.info("Uploading build...")
        let spinner = logger.spinner("Uploading to TestFlight")
        spinner.start()
        
        let result = try ProcessRunner.shared.run(uploadCommand, options: .default.with(timeout: TimeInterval(timeout)))
        
        if result.success {
            spinner.stop(success: true)
            logger.success("Build uploaded successfully!")
            
            // Add to beta groups if specified
            if let groups = groups {
                try await addToBetaGroups(groups: groups.components(separatedBy: ","))
            }
            
            // Submit for beta review if requested
            if submitBetaReview {
                logger.info("Submitting for beta review...")
                // Note: This would use App Store Connect API
                logger.warning("Beta review submission requires App Store Connect API setup")
            }
        } else {
            spinner.stop(success: false)
            throw DeployError.uploadFailed(result.stderr)
        }
    }
    
    // MARK: - App Store Deployment
    
    private func deployToAppStore(releaseNotes: String) async throws {
        let logger = Logger.shared
        
        logger.info("Deploying to App Store...")
        
        let ipaPath = try getIPAPath()
        
        if dryRun {
            logger.info("[DRY RUN] Would upload to App Store")
            return
        }
        
        // Validate build first
        if !skipValidation {
            logger.info("Validating build...")
            try await validateBuild(ipaPath: ipaPath)
        }
        
        // Upload build
        let uploadCommand = try buildUploadCommand(ipaPath: ipaPath)
        
        logger.info("Uploading build...")
        let result = try ProcessRunner.shared.run(uploadCommand, options: .default.with(timeout: TimeInterval(timeout)))
        
        guard result.success else {
            throw DeployError.uploadFailed(result.stderr)
        }
        
        logger.success("Build uploaded successfully!")
        
        // Submit for review if requested
        if submitReview {
            logger.info("Submitting for App Store review...")
            logger.warning("Review submission requires App Store Connect API setup")
        }
    }
    
    // MARK: - Firebase Deployment
    
    private func deployToFirebase(releaseNotes: String) async throws {
        let logger = Logger.shared
        
        logger.info("Deploying to Firebase App Distribution...")
        
        let ipaPath = try getIPAPath()
        
        guard let appId = firebaseAppId ?? ProcessInfo.processInfo.environment["FIREBASE_APP_ID"] else {
            throw DeployError.missingConfiguration("Firebase App ID not specified")
        }
        
        if dryRun {
            logger.info("[DRY RUN] Would upload to Firebase")
            return
        }
        
        var command = "firebase appdistribution:distribute '\(ipaPath)'"
        command += " --app '\(appId)'"
        
        if let groups = groups {
            command += " --groups '\(groups)'"
        }
        
        if let testers = testers {
            command += " --testers '\(testers)'"
        }
        
        command += " --release-notes '\(releaseNotes.replacingOccurrences(of: "'", with: "\\'"))'"
        
        logger.debug("Command: \(command)")
        
        let result = try ProcessRunner.shared.run(command, options: .default.with(printOutput: verbose))
        
        guard result.success else {
            throw DeployError.uploadFailed(result.stderr)
        }
        
        logger.success("Build uploaded to Firebase!")
    }
    
    // MARK: - App Center Deployment
    
    private func deployToAppCenter(releaseNotes: String) async throws {
        let logger = Logger.shared
        
        logger.info("Deploying to App Center...")
        
        let ipaPath = try getIPAPath()
        
        guard let owner = appCenterOwner ?? ProcessInfo.processInfo.environment["APPCENTER_OWNER"],
              let app = appCenterApp ?? ProcessInfo.processInfo.environment["APPCENTER_APP"] else {
            throw DeployError.missingConfiguration("App Center owner/app not specified")
        }
        
        if dryRun {
            logger.info("[DRY RUN] Would upload to App Center")
            return
        }
        
        var command = "appcenter distribute release"
        command += " --app '\(owner)/\(app)'"
        command += " --file '\(ipaPath)'"
        
        if let groups = groups {
            command += " --group '\(groups)'"
        }
        
        command += " --release-notes '\(releaseNotes.replacingOccurrences(of: "'", with: "\\'"))'"
        
        if distribute {
            command += " --silent"
        }
        
        let result = try ProcessRunner.shared.run(command, options: .default.with(printOutput: verbose))
        
        guard result.success else {
            throw DeployError.uploadFailed(result.stderr)
        }
        
        logger.success("Build uploaded to App Center!")
    }
    
    // MARK: - Play Store Deployment
    
    private func deployToPlayStore(releaseNotes: String) async throws {
        let logger = Logger.shared
        
        logger.info("Deploying to Google Play Store...")
        
        if dryRun {
            logger.info("[DRY RUN] Would upload to Play Store")
            return
        }
        
        // This would use Google Play Developer API or Fastlane supply
        logger.warning("Play Store deployment requires additional configuration")
        logger.info("Use 'fastlane supply' or Google Play Developer API")
    }
    
    // MARK: - S3 Deployment
    
    private func deployToS3() async throws {
        let logger = Logger.shared
        
        logger.info("Deploying to S3...")
        
        let ipaPath = try getIPAPath()
        
        guard let bucket = ProcessInfo.processInfo.environment["S3_BUCKET"] else {
            throw DeployError.missingConfiguration("S3 bucket not specified")
        }
        
        if dryRun {
            logger.info("[DRY RUN] Would upload to S3")
            return
        }
        
        let fileName = (ipaPath as NSString).lastPathComponent
        let command = "aws s3 cp '\(ipaPath)' 's3://\(bucket)/\(fileName)'"
        
        let result = try ProcessRunner.shared.run(command, options: .default.with(printOutput: verbose))
        
        guard result.success else {
            throw DeployError.uploadFailed(result.stderr)
        }
        
        logger.success("Build uploaded to S3!")
    }
    
    // MARK: - Helpers
    
    private func getIPAPath() throws -> String {
        if let ipa = ipa {
            guard FileManager.default.fileExists(atPath: ipa) else {
                throw DeployError.fileNotFound(ipa)
            }
            return ipa
        }
        
        if let archive = archive {
            // Export archive to IPA
            return try exportArchive(archivePath: archive)
        }
        
        // Try to find IPA in common locations
        let searchPaths = [
            "build/export",
            "build",
            "DerivedData",
            "."
        ]
        
        for path in searchPaths {
            if let ipaFile = findIPA(in: path) {
                return ipaFile
            }
        }
        
        throw DeployError.noIPAFound
    }
    
    private func findIPA(in directory: String) -> String? {
        let fileManager = FileManager.default
        
        guard let contents = try? fileManager.contentsOfDirectory(atPath: directory) else {
            return nil
        }
        
        if let ipa = contents.first(where: { $0.hasSuffix(".ipa") }) {
            return "\(directory)/\(ipa)"
        }
        
        // Search subdirectories
        for item in contents {
            let path = "\(directory)/\(item)"
            var isDir: ObjCBool = false
            if fileManager.fileExists(atPath: path, isDirectory: &isDir), isDir.boolValue {
                if let ipa = findIPA(in: path) {
                    return ipa
                }
            }
        }
        
        return nil
    }
    
    private func exportArchive(archivePath: String) throws -> String {
        let logger = Logger.shared
        logger.info("Exporting archive to IPA...")
        
        let exportPath = "build/export"
        
        var command = "xcodebuild -exportArchive"
        command += " -archivePath '\(archivePath)'"
        command += " -exportPath '\(exportPath)'"
        
        if let exportOptions = exportOptions {
            command += " -exportOptionsPlist '\(exportOptions)'"
        }
        
        let result = try ProcessRunner.shared.run(command, options: .default.with(printOutput: verbose))
        
        guard result.success else {
            throw DeployError.exportFailed(result.stderr)
        }
        
        guard let ipaPath = findIPA(in: exportPath) else {
            throw DeployError.exportFailed("IPA not found after export")
        }
        
        return ipaPath
    }
    
    private func buildUploadCommand(ipaPath: String) throws -> String {
        var command = "xcrun altool --upload-app"
        command += " --type ios"
        command += " --file '\(ipaPath)'"
        
        if let apiKeyId = apiKeyId ?? ProcessInfo.processInfo.environment["ASC_KEY_ID"],
           let apiIssuerId = apiIssuerId ?? ProcessInfo.processInfo.environment["ASC_ISSUER_ID"] {
            command += " --apiKey '\(apiKeyId)'"
            command += " --apiIssuer '\(apiIssuerId)'"
        } else {
            // Fall back to Apple ID authentication
            guard let appleId = ProcessInfo.processInfo.environment["APPLE_ID"],
                  let appPassword = ProcessInfo.processInfo.environment["APP_SPECIFIC_PASSWORD"] else {
                throw DeployError.missingConfiguration("Apple credentials not configured")
            }
            
            command += " --username '\(appleId)'"
            command += " --password '@env:APP_SPECIFIC_PASSWORD'"
        }
        
        return command
    }
    
    private func validateBuild(ipaPath: String) async throws {
        let command = "xcrun altool --validate-app --file '\(ipaPath)' --type ios"
        let result = try ProcessRunner.shared.run(command)
        
        guard result.success else {
            throw DeployError.validationFailed(result.stderr)
        }
        
        Logger.shared.success("Build validation passed")
    }
    
    private func addToBetaGroups(groups: [String]) async throws {
        Logger.shared.info("Adding build to beta groups: \(groups.joined(separator: ", "))")
        // This would use App Store Connect API
    }
}

// MARK: - Deploy Errors

/// Errors that can occur during deployment
public enum DeployError: LocalizedError {
    case fileNotFound(String)
    case noIPAFound
    case exportFailed(String)
    case uploadFailed(String)
    case validationFailed(String)
    case missingConfiguration(String)
    case apiError(String)
    
    public var errorDescription: String? {
        switch self {
        case .fileNotFound(let path):
            return "File not found: \(path)"
        case .noIPAFound:
            return "No IPA file found. Specify with --ipa or --archive"
        case .exportFailed(let message):
            return "Archive export failed: \(message)"
        case .uploadFailed(let message):
            return "Upload failed: \(message)"
        case .validationFailed(let message):
            return "Validation failed: \(message)"
        case .missingConfiguration(let message):
            return "Missing configuration: \(message)"
        case .apiError(let message):
            return "API error: \(message)"
        }
    }
}
