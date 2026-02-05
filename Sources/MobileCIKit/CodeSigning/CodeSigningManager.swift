// CodeSigningManager.swift
// MobileCIKit
//
// Complete code signing management for iOS/macOS applications.
// Handles certificates, provisioning profiles, and keychain operations.

import Foundation
import CryptoSwift

// MARK: - Certificate Types

/// Types of Apple code signing certificates
public enum CertificateType: String, Codable, CaseIterable, Sendable {
    case development = "Apple Development"
    case distribution = "Apple Distribution"
    case iosDevelopment = "iPhone Developer"
    case iosDistribution = "iPhone Distribution"
    case macDevelopment = "Mac Developer"
    case macDistribution = "3rd Party Mac Developer Application"
    case macInstaller = "3rd Party Mac Developer Installer"
    case developerIdApplication = "Developer ID Application"
    case developerIdInstaller = "Developer ID Installer"
    
    public var keychainLabel: String {
        return rawValue
    }
    
    public var isDistribution: Bool {
        switch self {
        case .distribution, .iosDistribution, .macDistribution, .macInstaller,
             .developerIdApplication, .developerIdInstaller:
            return true
        default:
            return false
        }
    }
}

// MARK: - Certificate Info

/// Information about an installed certificate
public struct CertificateInfo: Codable, Sendable {
    public let commonName: String
    public let teamId: String
    public let teamName: String
    public let serialNumber: String
    public let sha1Fingerprint: String
    public let sha256Fingerprint: String
    public let notBefore: Date
    public let notAfter: Date
    public let type: CertificateType?
    public let keychain: String?
    
    public var isExpired: Bool {
        return Date() > notAfter
    }
    
    public var isValid: Bool {
        let now = Date()
        return now >= notBefore && now <= notAfter
    }
    
    public var expiresInDays: Int {
        let calendar = Calendar.current
        return calendar.dateComponents([.day], from: Date(), to: notAfter).day ?? 0
    }
    
    public var displayName: String {
        return "\(commonName) (\(teamId))"
    }
}

// MARK: - Provisioning Profile Types

/// Types of provisioning profiles
public enum ProfileType: String, Codable, CaseIterable, Sendable {
    case development = "Development"
    case appStore = "App Store"
    case adHoc = "Ad Hoc"
    case enterprise = "Enterprise"
    case macAppStore = "Mac App Store"
    case macDeveloperID = "Developer ID"
    
    public var exportMethod: ExportMethod {
        switch self {
        case .development: return .development
        case .appStore, .macAppStore: return .appStore
        case .adHoc: return .adHoc
        case .enterprise: return .enterprise
        case .macDeveloperID: return .developerID
        }
    }
}

// MARK: - Provisioning Profile Info

/// Information about a provisioning profile
public struct ProvisioningProfile: Codable, Sendable {
    public let uuid: String
    public let name: String
    public let teamId: String
    public let teamName: String
    public let appId: String
    public let bundleId: String
    public let type: ProfileType
    public let creationDate: Date
    public let expirationDate: Date
    public let platforms: [String]
    public let certificates: [String]
    public let devices: [String]?
    public let entitlements: [String: Any]
    public let path: String
    
    public var isExpired: Bool {
        return Date() > expirationDate
    }
    
    public var isValid: Bool {
        return !isExpired
    }
    
    public var expiresInDays: Int {
        let calendar = Calendar.current
        return calendar.dateComponents([.day], from: Date(), to: expirationDate).day ?? 0
    }
    
    public var isWildcard: Bool {
        return bundleId.hasSuffix("*")
    }
    
    public func matches(bundleId: String) -> Bool {
        if self.bundleId == bundleId {
            return true
        }
        if isWildcard {
            let prefix = self.bundleId.dropLast()
            return bundleId.hasPrefix(String(prefix))
        }
        return false
    }
    
    enum CodingKeys: String, CodingKey {
        case uuid, name, teamId, teamName, appId, bundleId, type
        case creationDate, expirationDate, platforms, certificates, devices, path
    }
    
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        uuid = try container.decode(String.self, forKey: .uuid)
        name = try container.decode(String.self, forKey: .name)
        teamId = try container.decode(String.self, forKey: .teamId)
        teamName = try container.decode(String.self, forKey: .teamName)
        appId = try container.decode(String.self, forKey: .appId)
        bundleId = try container.decode(String.self, forKey: .bundleId)
        type = try container.decode(ProfileType.self, forKey: .type)
        creationDate = try container.decode(Date.self, forKey: .creationDate)
        expirationDate = try container.decode(Date.self, forKey: .expirationDate)
        platforms = try container.decode([String].self, forKey: .platforms)
        certificates = try container.decode([String].self, forKey: .certificates)
        devices = try container.decodeIfPresent([String].self, forKey: .devices)
        path = try container.decode(String.self, forKey: .path)
        entitlements = [:]
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(uuid, forKey: .uuid)
        try container.encode(name, forKey: .name)
        try container.encode(teamId, forKey: .teamId)
        try container.encode(teamName, forKey: .teamName)
        try container.encode(appId, forKey: .appId)
        try container.encode(bundleId, forKey: .bundleId)
        try container.encode(type, forKey: .type)
        try container.encode(creationDate, forKey: .creationDate)
        try container.encode(expirationDate, forKey: .expirationDate)
        try container.encode(platforms, forKey: .platforms)
        try container.encode(certificates, forKey: .certificates)
        try container.encode(devices, forKey: .devices)
        try container.encode(path, forKey: .path)
    }
    
    init(
        uuid: String, name: String, teamId: String, teamName: String,
        appId: String, bundleId: String, type: ProfileType,
        creationDate: Date, expirationDate: Date, platforms: [String],
        certificates: [String], devices: [String]?, entitlements: [String: Any],
        path: String
    ) {
        self.uuid = uuid
        self.name = name
        self.teamId = teamId
        self.teamName = teamName
        self.appId = appId
        self.bundleId = bundleId
        self.type = type
        self.creationDate = creationDate
        self.expirationDate = expirationDate
        self.platforms = platforms
        self.certificates = certificates
        self.devices = devices
        self.entitlements = entitlements
        self.path = path
    }
}

// MARK: - Code Signing Manager

/// Manages code signing operations for Apple platforms
public final class CodeSigningManager: @unchecked Sendable {
    public static let shared = CodeSigningManager()
    
    private let fileManager = FileManager.default
    private let processRunner = ProcessRunner.shared
    private let logger = Logger.shared
    
    private let provisioningProfilesPath: String
    private let keychainPath: String
    
    private init() {
        let home = fileManager.homeDirectoryForCurrentUser.path
        provisioningProfilesPath = "\(home)/Library/MobileDevice/Provisioning Profiles"
        keychainPath = "\(home)/Library/Keychains"
    }
    
    // MARK: - Certificate Management
    
    /// List all installed code signing certificates
    public func listCertificates(keychain: String? = nil) throws -> [CertificateInfo] {
        var command = "security find-identity -v -p codesigning"
        if let keychain = keychain {
            command += " \"\(keychain)\""
        }
        
        let result = try processRunner.run(command)
        guard result.success else {
            throw CodeSigningError.securityCommandFailed(result.stderr)
        }
        
        return parseCertificates(from: result.stdout)
    }
    
    /// Find a certificate by team ID and type
    public func findCertificate(
        teamId: String,
        type: CertificateType? = nil,
        keychain: String? = nil
    ) throws -> CertificateInfo? {
        let certificates = try listCertificates(keychain: keychain)
        
        return certificates.first { cert in
            let matchesTeam = cert.teamId == teamId
            let matchesType = type == nil || cert.type == type
            return matchesTeam && matchesType && cert.isValid
        }
    }
    
    /// Import a certificate from a .p12 file
    public func importCertificate(
        p12Path: String,
        password: String,
        keychain: String? = nil,
        allowCodeSigning: Bool = true
    ) throws {
        let keychainArg = keychain ?? "login.keychain"
        
        var command = """
            security import "\(p12Path)" -P "\(password)" -k "\(keychainArg)" -T /usr/bin/codesign
            """
        
        if allowCodeSigning {
            command += " -A"
        }
        
        let result = try processRunner.run(command)
        
        if !result.success && !result.stderr.contains("already exists") {
            throw CodeSigningError.certificateImportFailed(result.stderr)
        }
        
        // Allow codesign to access the certificate
        if allowCodeSigning {
            _ = try? processRunner.run(
                "security set-key-partition-list -S apple-tool:,apple: -s -k \"\" \"\(keychainArg)\""
            )
        }
        
        logger.success("Certificate imported successfully")
    }
    
    /// Import certificate from base64 encoded string
    public func importCertificateFromBase64(
        base64: String,
        password: String,
        keychain: String? = nil
    ) throws {
        guard let data = Data(base64Encoded: base64) else {
            throw CodeSigningError.invalidCertificateData
        }
        
        let tempPath = NSTemporaryDirectory() + "cert_\(UUID().uuidString).p12"
        try data.write(to: URL(fileURLWithPath: tempPath))
        
        defer {
            try? fileManager.removeItem(atPath: tempPath)
        }
        
        try importCertificate(p12Path: tempPath, password: password, keychain: keychain)
    }
    
    /// Delete a certificate from keychain
    public func deleteCertificate(
        commonName: String,
        keychain: String? = nil
    ) throws {
        var command = "security delete-identity -c \"\(commonName)\""
        if let keychain = keychain {
            command += " \"\(keychain)\""
        }
        
        let result = try processRunner.run(command)
        if !result.success {
            throw CodeSigningError.certificateDeleteFailed(result.stderr)
        }
        
        logger.success("Certificate deleted: \(commonName)")
    }
    
    // MARK: - Keychain Management
    
    /// Create a new keychain
    public func createKeychain(name: String, password: String) throws -> String {
        let path = "\(keychainPath)/\(name).keychain-db"
        
        // Create keychain
        let createResult = try processRunner.run(
            "security create-keychain -p \"\(password)\" \"\(path)\""
        )
        
        if !createResult.success && !createResult.stderr.contains("already exists") {
            throw CodeSigningError.keychainCreationFailed(createResult.stderr)
        }
        
        // Set keychain settings
        _ = try? processRunner.run("security set-keychain-settings -t 21600 -u \"\(path)\"")
        
        // Unlock keychain
        try unlockKeychain(path: path, password: password)
        
        // Add to search list
        try addKeychainToSearchList(path: path)
        
        logger.success("Keychain created: \(name)")
        return path
    }
    
    /// Unlock a keychain
    public func unlockKeychain(path: String, password: String) throws {
        let result = try processRunner.run(
            "security unlock-keychain -p \"\(password)\" \"\(path)\""
        )
        
        if !result.success {
            throw CodeSigningError.keychainUnlockFailed(result.stderr)
        }
    }
    
    /// Lock a keychain
    public func lockKeychain(path: String) throws {
        let result = try processRunner.run("security lock-keychain \"\(path)\"")
        if !result.success {
            throw CodeSigningError.securityCommandFailed(result.stderr)
        }
    }
    
    /// Delete a keychain
    public func deleteKeychain(path: String) throws {
        let result = try processRunner.run("security delete-keychain \"\(path)\"")
        if !result.success && !result.stderr.contains("could not be found") {
            throw CodeSigningError.keychainDeleteFailed(result.stderr)
        }
        
        logger.success("Keychain deleted: \(path)")
    }
    
    /// Add keychain to search list
    public func addKeychainToSearchList(path: String) throws {
        let listResult = try processRunner.run("security list-keychains -d user")
        var keychains = listResult.stdout
            .components(separatedBy: "\n")
            .map { $0.trimmingCharacters(in: .whitespaces).replacingOccurrences(of: "\"", with: "") }
            .filter { !$0.isEmpty }
        
        if !keychains.contains(path) {
            keychains.insert(path, at: 0)
        }
        
        let keychainArgs = keychains.map { "\"\($0)\"" }.joined(separator: " ")
        let result = try processRunner.run("security list-keychains -d user -s \(keychainArgs)")
        
        if !result.success {
            throw CodeSigningError.securityCommandFailed(result.stderr)
        }
    }
    
    /// Get the default keychain
    public func getDefaultKeychain() throws -> String {
        let result = try processRunner.run("security default-keychain -d user")
        guard result.success else {
            throw CodeSigningError.securityCommandFailed(result.stderr)
        }
        
        return result.stdout
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .replacingOccurrences(of: "\"", with: "")
    }
    
    // MARK: - Provisioning Profile Management
    
    /// List all installed provisioning profiles
    public func listProfiles() throws -> [ProvisioningProfile] {
        guard fileManager.fileExists(atPath: provisioningProfilesPath) else {
            return []
        }
        
        let contents = try fileManager.contentsOfDirectory(atPath: provisioningProfilesPath)
        let profileFiles = contents.filter { $0.hasSuffix(".mobileprovision") || $0.hasSuffix(".provisionprofile") }
        
        return profileFiles.compactMap { file in
            let path = "\(provisioningProfilesPath)/\(file)"
            return try? parseProfile(at: path)
        }
    }
    
    /// Find a profile for a specific bundle ID
    public func findProfile(
        bundleId: String,
        type: ProfileType? = nil,
        teamId: String? = nil
    ) throws -> ProvisioningProfile? {
        let profiles = try listProfiles()
        
        return profiles.first { profile in
            let matchesBundleId = profile.matches(bundleId: bundleId)
            let matchesType = type == nil || profile.type == type
            let matchesTeam = teamId == nil || profile.teamId == teamId
            return matchesBundleId && matchesType && matchesTeam && profile.isValid
        }
    }
    
    /// Install a provisioning profile
    public func installProfile(at path: String) throws -> ProvisioningProfile {
        let profile = try parseProfile(at: path)
        
        // Create directory if needed
        if !fileManager.fileExists(atPath: provisioningProfilesPath) {
            try fileManager.createDirectory(
                atPath: provisioningProfilesPath,
                withIntermediateDirectories: true
            )
        }
        
        let destinationPath = "\(provisioningProfilesPath)/\(profile.uuid).mobileprovision"
        
        // Copy profile
        if fileManager.fileExists(atPath: destinationPath) {
            try fileManager.removeItem(atPath: destinationPath)
        }
        try fileManager.copyItem(atPath: path, toPath: destinationPath)
        
        logger.success("Profile installed: \(profile.name)")
        return profile
    }
    
    /// Install profile from base64 encoded string
    public func installProfileFromBase64(_ base64: String) throws -> ProvisioningProfile {
        guard let data = Data(base64Encoded: base64) else {
            throw CodeSigningError.invalidProfileData
        }
        
        let tempPath = NSTemporaryDirectory() + "profile_\(UUID().uuidString).mobileprovision"
        try data.write(to: URL(fileURLWithPath: tempPath))
        
        defer {
            try? fileManager.removeItem(atPath: tempPath)
        }
        
        return try installProfile(at: tempPath)
    }
    
    /// Remove a provisioning profile
    public func removeProfile(uuid: String) throws {
        let path = "\(provisioningProfilesPath)/\(uuid).mobileprovision"
        
        if fileManager.fileExists(atPath: path) {
            try fileManager.removeItem(atPath: path)
            logger.success("Profile removed: \(uuid)")
        }
    }
    
    /// Remove expired profiles
    public func removeExpiredProfiles() throws -> Int {
        let profiles = try listProfiles()
        var count = 0
        
        for profile in profiles where profile.isExpired {
            try removeProfile(uuid: profile.uuid)
            count += 1
        }
        
        logger.success("Removed \(count) expired profiles")
        return count
    }
    
    // MARK: - Code Signing Operations
    
    /// Sign an app bundle
    public func signApp(
        at path: String,
        identity: String,
        entitlements: String? = nil,
        force: Bool = true
    ) throws {
        var command = "codesign"
        
        if force {
            command += " --force"
        }
        
        command += " --sign \"\(identity)\""
        
        if let entitlements = entitlements {
            command += " --entitlements \"\(entitlements)\""
        }
        
        command += " --timestamp"
        command += " --options runtime"
        command += " \"\(path)\""
        
        let result = try processRunner.run(command)
        
        if !result.success {
            throw CodeSigningError.signingFailed(result.stderr)
        }
        
        logger.success("App signed: \(path)")
    }
    
    /// Verify code signature
    public func verifySignature(at path: String, deep: Bool = true) throws -> Bool {
        var command = "codesign --verify --verbose"
        if deep {
            command += " --deep"
        }
        command += " \"\(path)\""
        
        let result = try processRunner.run(command)
        return result.success
    }
    
    /// Get signing info for an app
    public func getSigningInfo(at path: String) throws -> [String: Any] {
        let result = try processRunner.run(
            "codesign -dvvv \"\(path)\" 2>&1"
        )
        
        var info: [String: Any] = [:]
        
        for line in result.stdout.components(separatedBy: "\n") {
            if let range = line.range(of: "=") {
                let key = String(line[..<range.lowerBound])
                let value = String(line[range.upperBound...])
                info[key] = value
            }
        }
        
        return info
    }
    
    // MARK: - Automatic Signing Setup
    
    /// Setup code signing for CI environment
    public func setupCICodeSigning(
        certificateBase64: String,
        certificatePassword: String,
        profilesBase64: [String],
        keychainName: String = "ci-signing",
        keychainPassword: String = "ci-password"
    ) async throws -> CICodeSigningSetup {
        logger.info("Setting up code signing for CI environment...")
        
        // Create temporary keychain
        let keychainPath = try createKeychain(name: keychainName, password: keychainPassword)
        
        // Import certificate
        try importCertificateFromBase64(
            base64: certificateBase64,
            password: certificatePassword,
            keychain: keychainPath
        )
        
        // Install profiles
        var installedProfiles: [ProvisioningProfile] = []
        for profileBase64 in profilesBase64 {
            let profile = try installProfileFromBase64(profileBase64)
            installedProfiles.append(profile)
        }
        
        // Get certificates
        let certificates = try listCertificates(keychain: keychainPath)
        
        guard let certificate = certificates.first else {
            throw CodeSigningError.noCertificateFound
        }
        
        logger.success("CI code signing setup complete")
        
        return CICodeSigningSetup(
            keychainPath: keychainPath,
            keychainPassword: keychainPassword,
            certificate: certificate,
            profiles: installedProfiles
        )
    }
    
    /// Cleanup CI code signing
    public func cleanupCICodeSigning(keychainPath: String) throws {
        try deleteKeychain(path: keychainPath)
        logger.success("CI code signing cleanup complete")
    }
    
    // MARK: - Private Helpers
    
    private func parseCertificates(from output: String) -> [CertificateInfo] {
        var certificates: [CertificateInfo] = []
        
        let pattern = #"^\s+\d+\)\s+([A-F0-9]+)\s+"(.+)"$"#
        let regex = try? NSRegularExpression(pattern: pattern, options: .anchorsMatchLines)
        
        let lines = output.components(separatedBy: "\n")
        
        for line in lines {
            guard let match = regex?.firstMatch(
                in: line,
                options: [],
                range: NSRange(line.startIndex..., in: line)
            ) else {
                continue
            }
            
            guard let fingerprintRange = Range(match.range(at: 1), in: line),
                  let nameRange = Range(match.range(at: 2), in: line) else {
                continue
            }
            
            let fingerprint = String(line[fingerprintRange])
            let fullName = String(line[nameRange])
            
            // Parse certificate details
            if let certInfo = parseCertificateName(fullName, fingerprint: fingerprint) {
                certificates.append(certInfo)
            }
        }
        
        return certificates
    }
    
    private func parseCertificateName(_ name: String, fingerprint: String) -> CertificateInfo? {
        // Pattern: "Type: Name (Team ID)"
        let pattern = #"^(.+?):\s+(.+?)\s+\(([A-Z0-9]+)\)$"#
        
        guard let regex = try? NSRegularExpression(pattern: pattern),
              let match = regex.firstMatch(
                in: name,
                options: [],
                range: NSRange(name.startIndex..., in: name)
              ),
              let typeRange = Range(match.range(at: 1), in: name),
              let commonNameRange = Range(match.range(at: 2), in: name),
              let teamIdRange = Range(match.range(at: 3), in: name) else {
            return nil
        }
        
        let typeStr = String(name[typeRange])
        let commonName = String(name[commonNameRange])
        let teamId = String(name[teamIdRange])
        let type = CertificateType(rawValue: typeStr)
        
        return CertificateInfo(
            commonName: commonName,
            teamId: teamId,
            teamName: commonName,
            serialNumber: "",
            sha1Fingerprint: fingerprint,
            sha256Fingerprint: "",
            notBefore: Date(),
            notAfter: Date().addingTimeInterval(365 * 24 * 60 * 60),
            type: type,
            keychain: nil
        )
    }
    
    private func parseProfile(at path: String) throws -> ProvisioningProfile {
        // Decode the profile plist
        let result = try processRunner.run(
            "security cms -D -i \"\(path)\""
        )
        
        guard result.success else {
            throw CodeSigningError.profileParseFailed(result.stderr)
        }
        
        guard let data = result.stdout.data(using: .utf8),
              let plist = try? PropertyListSerialization.propertyList(
                from: data,
                options: [],
                format: nil
              ) as? [String: Any] else {
            throw CodeSigningError.profileParseFailed("Invalid plist")
        }
        
        // Extract profile info
        guard let uuid = plist["UUID"] as? String,
              let name = plist["Name"] as? String,
              let teamIds = plist["TeamIdentifier"] as? [String],
              let teamId = teamIds.first,
              let teamName = plist["TeamName"] as? String,
              let appId = plist["Entitlements"] as? [String: Any],
              let bundleIdWithPrefix = appId["application-identifier"] as? String,
              let creationDate = plist["CreationDate"] as? Date,
              let expirationDate = plist["ExpirationDate"] as? Date else {
            throw CodeSigningError.profileParseFailed("Missing required fields")
        }
        
        // Extract bundle ID (remove team ID prefix)
        let bundleId = bundleIdWithPrefix
            .replacingOccurrences(of: "\(teamId).", with: "")
        
        // Determine profile type
        let profileType = determineProfileType(from: plist)
        
        // Get platforms
        let platforms = plist["Platform"] as? [String] ?? []
        
        // Get certificates
        let certData = plist["DeveloperCertificates"] as? [Data] ?? []
        let certificates = certData.map { $0.base64EncodedString() }
        
        // Get devices
        let devices = plist["ProvisionedDevices"] as? [String]
        
        // Get entitlements
        let entitlements = plist["Entitlements"] as? [String: Any] ?? [:]
        
        return ProvisioningProfile(
            uuid: uuid,
            name: name,
            teamId: teamId,
            teamName: teamName,
            appId: bundleIdWithPrefix,
            bundleId: bundleId,
            type: profileType,
            creationDate: creationDate,
            expirationDate: expirationDate,
            platforms: platforms,
            certificates: certificates,
            devices: devices,
            entitlements: entitlements,
            path: path
        )
    }
    
    private func determineProfileType(from plist: [String: Any]) -> ProfileType {
        let entitlements = plist["Entitlements"] as? [String: Any] ?? [:]
        let hasGetTaskAllow = entitlements["get-task-allow"] as? Bool ?? false
        let hasDevices = plist["ProvisionedDevices"] != nil
        let hasProvisionAllDevices = plist["ProvisionsAllDevices"] as? Bool ?? false
        
        if hasProvisionAllDevices {
            return .enterprise
        } else if hasGetTaskAllow {
            return .development
        } else if hasDevices {
            return .adHoc
        } else {
            return .appStore
        }
    }
}

// MARK: - CI Code Signing Setup

/// Result of CI code signing setup
public struct CICodeSigningSetup: Sendable {
    public let keychainPath: String
    public let keychainPassword: String
    public let certificate: CertificateInfo
    public let profiles: [ProvisioningProfile]
    
    public var exportOptions: ExportOptions {
        let method = profiles.first?.type.exportMethod ?? .appStore
        return ExportOptions(
            method: method,
            teamId: certificate.teamId,
            signingStyle: .manual,
            signingIdentity: certificate.commonName,
            provisioningProfiles: Dictionary(uniqueKeysWithValues: profiles.map { ($0.bundleId, $0.name) })
        )
    }
}

// MARK: - Code Signing Errors

/// Errors that can occur during code signing operations
public enum CodeSigningError: LocalizedError {
    case securityCommandFailed(String)
    case certificateImportFailed(String)
    case certificateDeleteFailed(String)
    case keychainCreationFailed(String)
    case keychainUnlockFailed(String)
    case keychainDeleteFailed(String)
    case profileParseFailed(String)
    case profileInstallFailed(String)
    case signingFailed(String)
    case noCertificateFound
    case noProfileFound
    case invalidCertificateData
    case invalidProfileData
    case entitlementsNotFound
    
    public var errorDescription: String? {
        switch self {
        case .securityCommandFailed(let msg):
            return "Security command failed: \(msg)"
        case .certificateImportFailed(let msg):
            return "Certificate import failed: \(msg)"
        case .certificateDeleteFailed(let msg):
            return "Certificate deletion failed: \(msg)"
        case .keychainCreationFailed(let msg):
            return "Keychain creation failed: \(msg)"
        case .keychainUnlockFailed(let msg):
            return "Keychain unlock failed: \(msg)"
        case .keychainDeleteFailed(let msg):
            return "Keychain deletion failed: \(msg)"
        case .profileParseFailed(let msg):
            return "Profile parsing failed: \(msg)"
        case .profileInstallFailed(let msg):
            return "Profile installation failed: \(msg)"
        case .signingFailed(let msg):
            return "Code signing failed: \(msg)"
        case .noCertificateFound:
            return "No valid code signing certificate found"
        case .noProfileFound:
            return "No matching provisioning profile found"
        case .invalidCertificateData:
            return "Invalid certificate data"
        case .invalidProfileData:
            return "Invalid provisioning profile data"
        case .entitlementsNotFound:
            return "Entitlements file not found"
        }
    }
}
