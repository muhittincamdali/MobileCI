// Models.swift
// MobileCIKit
//
// Core data models for MobileCI framework.

import Foundation

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
