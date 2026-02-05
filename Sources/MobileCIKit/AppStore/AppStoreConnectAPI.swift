// AppStoreConnectAPI.swift
// MobileCIKit
//
// App Store Connect API client for TestFlight and App Store deployment.
// Supports JWT authentication and all essential ASC endpoints.

import Foundation
import AsyncHTTPClient
import NIOCore
import CryptoSwift

// MARK: - App Store Connect Configuration

/// Configuration for App Store Connect API
public struct AppStoreConnectConfig: Codable, Sendable {
    public let keyId: String
    public let issuerId: String
    public let privateKey: String
    public let bundleId: String?
    
    public init(
        keyId: String,
        issuerId: String,
        privateKey: String,
        bundleId: String? = nil
    ) {
        self.keyId = keyId
        self.issuerId = issuerId
        self.privateKey = privateKey
        self.bundleId = bundleId
    }
    
    /// Create config from environment variables
    public static func fromEnvironment() throws -> AppStoreConnectConfig {
        guard let keyId = ProcessInfo.processInfo.environment["ASC_KEY_ID"],
              let issuerId = ProcessInfo.processInfo.environment["ASC_ISSUER_ID"],
              let privateKey = ProcessInfo.processInfo.environment["ASC_PRIVATE_KEY"] else {
            throw AppStoreConnectError.missingCredentials
        }
        
        return AppStoreConnectConfig(
            keyId: keyId,
            issuerId: issuerId,
            privateKey: privateKey,
            bundleId: ProcessInfo.processInfo.environment["BUNDLE_ID"]
        )
    }
    
    /// Create config from file
    public static func fromFile(_ path: String) throws -> AppStoreConnectConfig {
        let data = try Data(contentsOf: URL(fileURLWithPath: path))
        return try JSONDecoder().decode(AppStoreConnectConfig.self, from: data)
    }
}

// MARK: - JWT Token Generator

/// Generates JWT tokens for App Store Connect API authentication
public final class ASCTokenGenerator {
    private let keyId: String
    private let issuerId: String
    private let privateKey: String
    
    public init(config: AppStoreConnectConfig) {
        self.keyId = config.keyId
        self.issuerId = config.issuerId
        self.privateKey = config.privateKey
    }
    
    /// Generate a JWT token
    public func generateToken() throws -> String {
        let now = Date()
        let expiration = now.addingTimeInterval(20 * 60) // 20 minutes
        
        let header: [String: Any] = [
            "alg": "ES256",
            "kid": keyId,
            "typ": "JWT"
        ]
        
        let payload: [String: Any] = [
            "iss": issuerId,
            "iat": Int(now.timeIntervalSince1970),
            "exp": Int(expiration.timeIntervalSince1970),
            "aud": "appstoreconnect-v1"
        ]
        
        let headerData = try JSONSerialization.data(withJSONObject: header)
        let payloadData = try JSONSerialization.data(withJSONObject: payload)
        
        let headerBase64 = headerData.base64URLEncodedString()
        let payloadBase64 = payloadData.base64URLEncodedString()
        
        let signatureInput = "\(headerBase64).\(payloadBase64)"
        
        guard let signature = signES256(signatureInput) else {
            throw AppStoreConnectError.tokenGenerationFailed
        }
        
        return "\(signatureInput).\(signature)"
    }
    
    private func signES256(_ input: String) -> String? {
        // Use security framework for ES256 signing
        guard let inputData = input.data(using: .utf8) else { return nil }
        
        // Parse the private key
        let cleanKey = privateKey
            .replacingOccurrences(of: "-----BEGIN PRIVATE KEY-----", with: "")
            .replacingOccurrences(of: "-----END PRIVATE KEY-----", with: "")
            .replacingOccurrences(of: "\n", with: "")
            .replacingOccurrences(of: " ", with: "")
        
        guard let keyData = Data(base64Encoded: cleanKey) else { return nil }
        
        // Create SecKey
        let attributes: [String: Any] = [
            kSecAttrKeyType as String: kSecAttrKeyTypeECSECPrimeRandom,
            kSecAttrKeyClass as String: kSecAttrKeyClassPrivate,
            kSecAttrKeySizeInBits as String: 256
        ]
        
        var error: Unmanaged<CFError>?
        
        // Try to parse as PKCS8
        let keyOffset = 26 // PKCS8 header offset for EC keys
        let rawKeyData: Data
        if keyData.count > keyOffset + 32 {
            rawKeyData = keyData.suffix(from: keyOffset)
        } else {
            rawKeyData = keyData
        }
        
        guard let secKey = SecKeyCreateWithData(
            rawKeyData as CFData,
            attributes as CFDictionary,
            &error
        ) else {
            return nil
        }
        
        // Sign the data
        guard let signatureData = SecKeyCreateSignature(
            secKey,
            .ecdsaSignatureMessageX962SHA256,
            inputData as CFData,
            &error
        ) else {
            return nil
        }
        
        // Convert DER signature to raw format
        let signature = convertDERToRaw(signatureData as Data)
        return signature.base64URLEncodedString()
    }
    
    private func convertDERToRaw(_ der: Data) -> Data {
        // DER signature format: 0x30 [length] 0x02 [r_length] [r] 0x02 [s_length] [s]
        var index = 0
        
        guard der.count > 4, der[index] == 0x30 else { return der }
        index += 1
        
        // Skip total length
        if der[index] & 0x80 != 0 {
            index += Int(der[index] & 0x7F) + 1
        } else {
            index += 1
        }
        
        guard der[index] == 0x02 else { return der }
        index += 1
        
        var rLength = Int(der[index])
        index += 1
        
        // Skip leading zero if present
        if der[index] == 0x00 {
            index += 1
            rLength -= 1
        }
        
        let r = der[index..<(index + rLength)]
        index += rLength
        
        guard der[index] == 0x02 else { return der }
        index += 1
        
        var sLength = Int(der[index])
        index += 1
        
        if der[index] == 0x00 {
            index += 1
            sLength -= 1
        }
        
        let s = der[index..<(index + sLength)]
        
        // Pad r and s to 32 bytes each
        var raw = Data()
        if r.count < 32 {
            raw.append(contentsOf: [UInt8](repeating: 0, count: 32 - r.count))
        }
        raw.append(r)
        if s.count < 32 {
            raw.append(contentsOf: [UInt8](repeating: 0, count: 32 - s.count))
        }
        raw.append(s)
        
        return raw
    }
}

// MARK: - App Store Connect Client

/// Client for interacting with App Store Connect API
public final class AppStoreConnectClient: @unchecked Sendable {
    private let config: AppStoreConnectConfig
    private let tokenGenerator: ASCTokenGenerator
    private let httpClient: HTTPClient
    private let baseURL = "https://api.appstoreconnect.apple.com/v1"
    
    private var cachedToken: String?
    private var tokenExpiration: Date?
    
    public init(config: AppStoreConnectConfig) {
        self.config = config
        self.tokenGenerator = ASCTokenGenerator(config: config)
        self.httpClient = HTTPClient(eventLoopGroupProvider: .singleton)
    }
    
    deinit {
        try? httpClient.syncShutdown()
    }
    
    // MARK: - Authentication
    
    private func getToken() throws -> String {
        if let token = cachedToken, let expiration = tokenExpiration, expiration > Date() {
            return token
        }
        
        let token = try tokenGenerator.generateToken()
        cachedToken = token
        tokenExpiration = Date().addingTimeInterval(15 * 60) // 15 minutes cache
        return token
    }
    
    // MARK: - Apps
    
    /// List all apps
    public func listApps() async throws -> [ASCApp] {
        let response: ASCResponse<[ASCApp]> = try await request(
            method: .GET,
            path: "/apps",
            query: ["limit": "200"]
        )
        return response.data
    }
    
    /// Get app by bundle ID
    public func getApp(bundleId: String) async throws -> ASCApp? {
        let apps = try await listApps()
        return apps.first { $0.attributes.bundleId == bundleId }
    }
    
    /// Get app by ID
    public func getApp(id: String) async throws -> ASCApp {
        let response: ASCResponse<ASCApp> = try await request(
            method: .GET,
            path: "/apps/\(id)"
        )
        return response.data
    }
    
    // MARK: - Builds
    
    /// List builds for an app
    public func listBuilds(
        appId: String,
        limit: Int = 10,
        preReleaseVersion: String? = nil
    ) async throws -> [ASCBuild] {
        var query: [String: String] = [
            "filter[app]": appId,
            "limit": "\(limit)",
            "sort": "-uploadedDate"
        ]
        
        if let version = preReleaseVersion {
            query["filter[preReleaseVersion.version]"] = version
        }
        
        let response: ASCResponse<[ASCBuild]> = try await request(
            method: .GET,
            path: "/builds",
            query: query
        )
        return response.data
    }
    
    /// Get build by ID
    public func getBuild(id: String) async throws -> ASCBuild {
        let response: ASCResponse<ASCBuild> = try await request(
            method: .GET,
            path: "/builds/\(id)"
        )
        return response.data
    }
    
    /// Wait for build processing to complete
    public func waitForBuildProcessing(
        appId: String,
        version: String,
        buildNumber: String,
        timeout: TimeInterval = 3600
    ) async throws -> ASCBuild {
        let startTime = Date()
        
        while Date().timeIntervalSince(startTime) < timeout {
            let builds = try await listBuilds(appId: appId, limit: 20)
            
            if let build = builds.first(where: {
                $0.attributes.version == buildNumber
            }) {
                switch build.attributes.processingState {
                case "PROCESSING":
                    Logger.shared.info("Build still processing...")
                    try await Task.sleep(nanoseconds: 30_000_000_000) // 30 seconds
                case "VALID":
                    return build
                case "INVALID":
                    throw AppStoreConnectError.buildProcessingFailed(build.id)
                default:
                    try await Task.sleep(nanoseconds: 30_000_000_000)
                }
            } else {
                Logger.shared.info("Waiting for build to appear...")
                try await Task.sleep(nanoseconds: 30_000_000_000)
            }
        }
        
        throw AppStoreConnectError.buildProcessingTimeout
    }
    
    // MARK: - TestFlight
    
    /// List beta groups for an app
    public func listBetaGroups(appId: String) async throws -> [ASCBetaGroup] {
        let response: ASCResponse<[ASCBetaGroup]> = try await request(
            method: .GET,
            path: "/betaGroups",
            query: ["filter[app]": appId]
        )
        return response.data
    }
    
    /// Create a beta group
    public func createBetaGroup(
        appId: String,
        name: String,
        isInternal: Bool = false,
        publicLinkEnabled: Bool = false
    ) async throws -> ASCBetaGroup {
        let body: [String: Any] = [
            "data": [
                "type": "betaGroups",
                "attributes": [
                    "name": name,
                    "isInternalGroup": isInternal,
                    "publicLinkEnabled": publicLinkEnabled
                ],
                "relationships": [
                    "app": [
                        "data": [
                            "type": "apps",
                            "id": appId
                        ]
                    ]
                ]
            ]
        ]
        
        let response: ASCResponse<ASCBetaGroup> = try await request(
            method: .POST,
            path: "/betaGroups",
            body: body
        )
        return response.data
    }
    
    /// Add build to beta group
    public func addBuildToBetaGroup(buildId: String, betaGroupId: String) async throws {
        let body: [String: Any] = [
            "data": [
                [
                    "type": "builds",
                    "id": buildId
                ]
            ]
        ]
        
        let _: EmptyResponse = try await request(
            method: .POST,
            path: "/betaGroups/\(betaGroupId)/relationships/builds",
            body: body
        )
    }
    
    /// Submit build to external beta review
    public func submitForBetaReview(buildId: String) async throws -> ASCBetaAppReviewSubmission {
        let body: [String: Any] = [
            "data": [
                "type": "betaAppReviewSubmissions",
                "relationships": [
                    "build": [
                        "data": [
                            "type": "builds",
                            "id": buildId
                        ]
                    ]
                ]
            ]
        ]
        
        let response: ASCResponse<ASCBetaAppReviewSubmission> = try await request(
            method: .POST,
            path: "/betaAppReviewSubmissions",
            body: body
        )
        return response.data
    }
    
    /// Add testers to beta group
    public func addTestersToBetaGroup(
        betaGroupId: String,
        emails: [String]
    ) async throws {
        for email in emails {
            let body: [String: Any] = [
                "data": [
                    "type": "betaTesters",
                    "attributes": [
                        "email": email
                    ],
                    "relationships": [
                        "betaGroups": [
                            "data": [
                                [
                                    "type": "betaGroups",
                                    "id": betaGroupId
                                ]
                            ]
                        ]
                    ]
                ]
            ]
            
            let _: ASCResponse<ASCBetaTester> = try await request(
                method: .POST,
                path: "/betaTesters",
                body: body
            )
        }
    }
    
    // MARK: - App Store Submission
    
    /// Create App Store version
    public func createAppStoreVersion(
        appId: String,
        versionString: String,
        platform: ASCPlatform = .iOS
    ) async throws -> ASCAppStoreVersion {
        let body: [String: Any] = [
            "data": [
                "type": "appStoreVersions",
                "attributes": [
                    "versionString": versionString,
                    "platform": platform.rawValue
                ],
                "relationships": [
                    "app": [
                        "data": [
                            "type": "apps",
                            "id": appId
                        ]
                    ]
                ]
            ]
        ]
        
        let response: ASCResponse<ASCAppStoreVersion> = try await request(
            method: .POST,
            path: "/appStoreVersions",
            body: body
        )
        return response.data
    }
    
    /// Get current App Store version
    public func getAppStoreVersion(appId: String, platform: ASCPlatform = .iOS) async throws -> ASCAppStoreVersion? {
        let response: ASCResponse<[ASCAppStoreVersion]> = try await request(
            method: .GET,
            path: "/apps/\(appId)/appStoreVersions",
            query: ["filter[platform]": platform.rawValue]
        )
        return response.data.first
    }
    
    /// Set build for App Store version
    public func setBuildForVersion(versionId: String, buildId: String) async throws {
        let body: [String: Any] = [
            "data": [
                "type": "builds",
                "id": buildId
            ]
        ]
        
        let _: EmptyResponse = try await request(
            method: .PATCH,
            path: "/appStoreVersions/\(versionId)/relationships/build",
            body: body
        )
    }
    
    /// Submit for App Store review
    public func submitForReview(versionId: String) async throws -> ASCAppStoreVersionSubmission {
        let body: [String: Any] = [
            "data": [
                "type": "appStoreVersionSubmissions",
                "relationships": [
                    "appStoreVersion": [
                        "data": [
                            "type": "appStoreVersions",
                            "id": versionId
                        ]
                    ]
                ]
            ]
        ]
        
        let response: ASCResponse<ASCAppStoreVersionSubmission> = try await request(
            method: .POST,
            path: "/appStoreVersionSubmissions",
            body: body
        )
        return response.data
    }
    
    // MARK: - Devices
    
    /// List registered devices
    public func listDevices(platform: ASCPlatform? = nil) async throws -> [ASCDevice] {
        var query: [String: String] = ["limit": "200"]
        if let platform = platform {
            query["filter[platform]"] = platform.rawValue
        }
        
        let response: ASCResponse<[ASCDevice]> = try await request(
            method: .GET,
            path: "/devices",
            query: query
        )
        return response.data
    }
    
    /// Register a new device
    public func registerDevice(
        name: String,
        udid: String,
        platform: ASCPlatform = .iOS
    ) async throws -> ASCDevice {
        let body: [String: Any] = [
            "data": [
                "type": "devices",
                "attributes": [
                    "name": name,
                    "udid": udid,
                    "platform": platform.rawValue
                ]
            ]
        ]
        
        let response: ASCResponse<ASCDevice> = try await request(
            method: .POST,
            path: "/devices",
            body: body
        )
        return response.data
    }
    
    // MARK: - Certificates
    
    /// List certificates
    public func listCertificates() async throws -> [ASCCertificate] {
        let response: ASCResponse<[ASCCertificate]> = try await request(
            method: .GET,
            path: "/certificates",
            query: ["limit": "200"]
        )
        return response.data
    }
    
    // MARK: - Profiles
    
    /// List provisioning profiles
    public func listProfiles() async throws -> [ASCProfile] {
        let response: ASCResponse<[ASCProfile]> = try await request(
            method: .GET,
            path: "/profiles",
            query: ["limit": "200"]
        )
        return response.data
    }
    
    /// Download a provisioning profile
    public func downloadProfile(id: String) async throws -> Data {
        let profile: ASCResponse<ASCProfile> = try await request(
            method: .GET,
            path: "/profiles/\(id)"
        )
        
        guard let content = profile.data.attributes.profileContent,
              let data = Data(base64Encoded: content) else {
            throw AppStoreConnectError.profileDownloadFailed
        }
        
        return data
    }
    
    // MARK: - HTTP Client
    
    private func request<T: Decodable>(
        method: HTTPMethod,
        path: String,
        query: [String: String]? = nil,
        body: [String: Any]? = nil
    ) async throws -> T {
        let token = try getToken()
        
        var urlString = baseURL + path
        if let query = query, !query.isEmpty {
            let queryString = query.map { "\($0.key)=\($0.value.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? $0.value)" }
                .joined(separator: "&")
            urlString += "?\(queryString)"
        }
        
        var request = HTTPClientRequest(url: urlString)
        request.method = method
        request.headers.add(name: "Authorization", value: "Bearer \(token)")
        request.headers.add(name: "Content-Type", value: "application/json")
        
        if let body = body {
            let bodyData = try JSONSerialization.data(withJSONObject: body)
            request.body = .bytes(ByteBuffer(data: bodyData))
        }
        
        let response = try await httpClient.execute(request, timeout: .seconds(60))
        let responseBody = try await response.body.collect(upTo: 10 * 1024 * 1024)
        let responseData = Data(buffer: responseBody)
        
        guard response.status.code >= 200 && response.status.code < 300 else {
            if let errorResponse = try? JSONDecoder().decode(ASCErrorResponse.self, from: responseData) {
                throw AppStoreConnectError.apiError(errorResponse.errors.first?.detail ?? "Unknown error")
            }
            throw AppStoreConnectError.requestFailed(Int(response.status.code))
        }
        
        if T.self == EmptyResponse.self {
            return EmptyResponse() as! T
        }
        
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return try decoder.decode(T.self, from: responseData)
    }
}

// MARK: - HTTP Method

public enum HTTPMethod: String {
    case GET
    case POST
    case PATCH
    case DELETE
}

// MARK: - Empty Response

private struct EmptyResponse: Decodable {}

// MARK: - API Response Types

public struct ASCResponse<T: Decodable>: Decodable {
    public let data: T
    public let links: ASCPagedLinks?
    public let meta: ASCPagingInfo?
}

public struct ASCPagedLinks: Decodable {
    public let `self`: String
    public let next: String?
    public let first: String?
}

public struct ASCPagingInfo: Decodable {
    public let paging: ASCPaging
}

public struct ASCPaging: Decodable {
    public let total: Int
    public let limit: Int
}

public struct ASCErrorResponse: Decodable {
    public let errors: [ASCError]
}

public struct ASCError: Decodable {
    public let id: String
    public let status: String
    public let code: String
    public let title: String
    public let detail: String
}

// MARK: - Resource Types

public struct ASCApp: Codable, Sendable {
    public let id: String
    public let type: String
    public let attributes: ASCAppAttributes
}

public struct ASCAppAttributes: Codable, Sendable {
    public let name: String
    public let bundleId: String
    public let sku: String
    public let primaryLocale: String
}

public struct ASCBuild: Codable, Sendable {
    public let id: String
    public let type: String
    public let attributes: ASCBuildAttributes
}

public struct ASCBuildAttributes: Codable, Sendable {
    public let version: String
    public let uploadedDate: Date?
    public let expirationDate: Date?
    public let processingState: String
    public let minOsVersion: String?
    public let iconAssetToken: ASCImageAsset?
}

public struct ASCImageAsset: Codable, Sendable {
    public let width: Int
    public let height: Int
    public let templateUrl: String
}

public struct ASCBetaGroup: Codable, Sendable {
    public let id: String
    public let type: String
    public let attributes: ASCBetaGroupAttributes
}

public struct ASCBetaGroupAttributes: Codable, Sendable {
    public let name: String
    public let isInternalGroup: Bool
    public let publicLinkEnabled: Bool?
    public let publicLink: String?
}

public struct ASCBetaTester: Codable, Sendable {
    public let id: String
    public let type: String
    public let attributes: ASCBetaTesterAttributes
}

public struct ASCBetaTesterAttributes: Codable, Sendable {
    public let email: String?
    public let firstName: String?
    public let lastName: String?
    public let inviteType: String?
}

public struct ASCBetaAppReviewSubmission: Codable, Sendable {
    public let id: String
    public let type: String
    public let attributes: ASCBetaAppReviewSubmissionAttributes
}

public struct ASCBetaAppReviewSubmissionAttributes: Codable, Sendable {
    public let betaReviewState: String
    public let submittedDate: Date?
}

public struct ASCAppStoreVersion: Codable, Sendable {
    public let id: String
    public let type: String
    public let attributes: ASCAppStoreVersionAttributes
}

public struct ASCAppStoreVersionAttributes: Codable, Sendable {
    public let versionString: String
    public let platform: String
    public let appStoreState: String
    public let createdDate: Date?
}

public struct ASCAppStoreVersionSubmission: Codable, Sendable {
    public let id: String
    public let type: String
}

public struct ASCDevice: Codable, Sendable {
    public let id: String
    public let type: String
    public let attributes: ASCDeviceAttributes
}

public struct ASCDeviceAttributes: Codable, Sendable {
    public let name: String
    public let udid: String
    public let platform: String
    public let status: String
    public let deviceClass: String
    public let model: String?
}

public struct ASCCertificate: Codable, Sendable {
    public let id: String
    public let type: String
    public let attributes: ASCCertificateAttributes
}

public struct ASCCertificateAttributes: Codable, Sendable {
    public let name: String
    public let certificateType: String
    public let expirationDate: Date
    public let serialNumber: String
}

public struct ASCProfile: Codable, Sendable {
    public let id: String
    public let type: String
    public let attributes: ASCProfileAttributes
}

public struct ASCProfileAttributes: Codable, Sendable {
    public let name: String
    public let profileType: String
    public let profileState: String
    public let expirationDate: Date
    public let uuid: String
    public let profileContent: String?
}

// MARK: - Platform

public enum ASCPlatform: String, Codable, Sendable {
    case iOS = "IOS"
    case macOS = "MAC_OS"
    case tvOS = "TV_OS"
    case watchOS = "WATCH_OS"
    case visionOS = "VISION_OS"
}

// MARK: - App Store Connect Errors

public enum AppStoreConnectError: LocalizedError {
    case missingCredentials
    case tokenGenerationFailed
    case requestFailed(Int)
    case apiError(String)
    case buildProcessingFailed(String)
    case buildProcessingTimeout
    case appNotFound
    case profileDownloadFailed
    case uploadFailed(String)
    
    public var errorDescription: String? {
        switch self {
        case .missingCredentials:
            return "App Store Connect credentials not configured"
        case .tokenGenerationFailed:
            return "Failed to generate JWT token"
        case .requestFailed(let code):
            return "API request failed with status code \(code)"
        case .apiError(let message):
            return "API error: \(message)"
        case .buildProcessingFailed(let id):
            return "Build processing failed: \(id)"
        case .buildProcessingTimeout:
            return "Build processing timed out"
        case .appNotFound:
            return "App not found in App Store Connect"
        case .profileDownloadFailed:
            return "Failed to download provisioning profile"
        case .uploadFailed(let message):
            return "Upload failed: \(message)"
        }
    }
}

// MARK: - Data Extension

extension Data {
    func base64URLEncodedString() -> String {
        return base64EncodedString()
            .replacingOccurrences(of: "+", with: "-")
            .replacingOccurrences(of: "/", with: "_")
            .replacingOccurrences(of: "=", with: "")
    }
}
