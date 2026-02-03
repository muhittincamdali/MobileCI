// ConfigParser.swift
// MobileCIKit
//
// Configuration file parsing and validation for MobileCI.

import Foundation
import Yams

// MARK: - MobileCI Configuration

/// Main configuration structure for MobileCI projects
public struct MobileCIConfig: Codable, Sendable {
    public let version: String
    public let name: String
    public let platforms: [PlatformConfig]
    public let build: BuildConfig?
    public let test: TestConfig?
    public let deploy: DeployConfig?
    public let lint: LintConfig?
    public let cache: CacheConfig?
    public let notifications: NotificationConfig?
    public let environment: [String: String]?
    public let secrets: [String]?
    public let triggers: TriggersConfig?
    public let jobs: [String: JobConfig]?
    
    public init(
        version: String = "1.0",
        name: String,
        platforms: [PlatformConfig] = [],
        build: BuildConfig? = nil,
        test: TestConfig? = nil,
        deploy: DeployConfig? = nil,
        lint: LintConfig? = nil,
        cache: CacheConfig? = nil,
        notifications: NotificationConfig? = nil,
        environment: [String: String]? = nil,
        secrets: [String]? = nil,
        triggers: TriggersConfig? = nil,
        jobs: [String: JobConfig]? = nil
    ) {
        self.version = version
        self.name = name
        self.platforms = platforms
        self.build = build
        self.test = test
        self.deploy = deploy
        self.lint = lint
        self.cache = cache
        self.notifications = notifications
        self.environment = environment
        self.secrets = secrets
        self.triggers = triggers
        self.jobs = jobs
    }
}

// MARK: - Platform Configuration

/// Configuration for a specific platform
public struct PlatformConfig: Codable, Sendable {
    public let platform: Platform
    public let enabled: Bool
    public let minVersion: String?
    public let project: String?
    public let workspace: String?
    public let scheme: String?
    public let target: String?
    public let configuration: BuildConfiguration?
    public let destination: String?
    public let buildSettings: [String: String]?
    public let environmentVariables: [String: String]?
    public let xcconfig: String?
    public let podfile: String?
    public let packagePath: String?
    
    public init(
        platform: Platform,
        enabled: Bool = true,
        minVersion: String? = nil,
        project: String? = nil,
        workspace: String? = nil,
        scheme: String? = nil,
        target: String? = nil,
        configuration: BuildConfiguration? = nil,
        destination: String? = nil,
        buildSettings: [String: String]? = nil,
        environmentVariables: [String: String]? = nil,
        xcconfig: String? = nil,
        podfile: String? = nil,
        packagePath: String? = nil
    ) {
        self.platform = platform
        self.enabled = enabled
        self.minVersion = minVersion
        self.project = project
        self.workspace = workspace
        self.scheme = scheme
        self.target = target
        self.configuration = configuration
        self.destination = destination
        self.buildSettings = buildSettings
        self.environmentVariables = environmentVariables
        self.xcconfig = xcconfig
        self.podfile = podfile
        self.packagePath = packagePath
    }
}

// MARK: - Build Configuration

/// Build-specific configuration
public struct BuildConfig: Codable, Sendable {
    public let clean: Bool
    public let parallel: Bool
    public let maxConcurrency: Int?
    public let derivedDataPath: String?
    public let archivePath: String?
    public let outputPath: String?
    public let exportOptions: ExportOptionsConfig?
    public let signing: SigningConfig?
    public let preBuildCommands: [String]?
    public let postBuildCommands: [String]?
    public let buildArguments: [String]?
    public let xcpretty: Bool
    public let generateDSYM: Bool
    public let enableBitcode: Bool
    public let enableTestability: Bool
    
    public init(
        clean: Bool = true,
        parallel: Bool = true,
        maxConcurrency: Int? = nil,
        derivedDataPath: String? = nil,
        archivePath: String? = nil,
        outputPath: String? = nil,
        exportOptions: ExportOptionsConfig? = nil,
        signing: SigningConfig? = nil,
        preBuildCommands: [String]? = nil,
        postBuildCommands: [String]? = nil,
        buildArguments: [String]? = nil,
        xcpretty: Bool = true,
        generateDSYM: Bool = true,
        enableBitcode: Bool = false,
        enableTestability: Bool = false
    ) {
        self.clean = clean
        self.parallel = parallel
        self.maxConcurrency = maxConcurrency
        self.derivedDataPath = derivedDataPath
        self.archivePath = archivePath
        self.outputPath = outputPath
        self.exportOptions = exportOptions
        self.signing = signing
        self.preBuildCommands = preBuildCommands
        self.postBuildCommands = postBuildCommands
        self.buildArguments = buildArguments
        self.xcpretty = xcpretty
        self.generateDSYM = generateDSYM
        self.enableBitcode = enableBitcode
        self.enableTestability = enableTestability
    }
}

/// Export options configuration
public struct ExportOptionsConfig: Codable, Sendable {
    public let method: String
    public let teamId: String?
    public let signingCertificate: String?
    public let signingStyle: String?
    public let provisioningProfiles: [String: String]?
    public let uploadBitcode: Bool?
    public let uploadSymbols: Bool?
    public let compileBitcode: Bool?
    public let thinning: String?
    
    public init(
        method: String = "app-store",
        teamId: String? = nil,
        signingCertificate: String? = nil,
        signingStyle: String? = nil,
        provisioningProfiles: [String: String]? = nil,
        uploadBitcode: Bool? = nil,
        uploadSymbols: Bool? = nil,
        compileBitcode: Bool? = nil,
        thinning: String? = nil
    ) {
        self.method = method
        self.teamId = teamId
        self.signingCertificate = signingCertificate
        self.signingStyle = signingStyle
        self.provisioningProfiles = provisioningProfiles
        self.uploadBitcode = uploadBitcode
        self.uploadSymbols = uploadSymbols
        self.compileBitcode = compileBitcode
        self.thinning = thinning
    }
}

/// Code signing configuration
public struct SigningConfig: Codable, Sendable {
    public let style: String
    public let identity: String?
    public let provisioningProfile: String?
    public let teamId: String?
    public let keychainPath: String?
    public let keychainPassword: String?
    public let certificatePath: String?
    public let certificatePassword: String?
    public let matchType: String?
    public let matchGitUrl: String?
    public let matchPassword: String?
    
    public init(
        style: String = "automatic",
        identity: String? = nil,
        provisioningProfile: String? = nil,
        teamId: String? = nil,
        keychainPath: String? = nil,
        keychainPassword: String? = nil,
        certificatePath: String? = nil,
        certificatePassword: String? = nil,
        matchType: String? = nil,
        matchGitUrl: String? = nil,
        matchPassword: String? = nil
    ) {
        self.style = style
        self.identity = identity
        self.provisioningProfile = provisioningProfile
        self.teamId = teamId
        self.keychainPath = keychainPath
        self.keychainPassword = keychainPassword
        self.certificatePath = certificatePath
        self.certificatePassword = certificatePassword
        self.matchType = matchType
        self.matchGitUrl = matchGitUrl
        self.matchPassword = matchPassword
    }
}

// MARK: - Test Configuration

/// Test-specific configuration
public struct TestConfig: Codable, Sendable {
    public let enabled: Bool
    public let parallel: Bool
    public let maxParallelism: Int?
    public let codeCoverage: Bool
    public let coverageTargets: [String]?
    public let minimumCoverage: Double?
    public let testPlan: String?
    public let skipTests: [String]?
    public let onlyTests: [String]?
    public let destinations: [String]?
    public let resultBundlePath: String?
    public let attachments: Bool
    public let retryCount: Int?
    public let timeout: Int?
    public let preTestCommands: [String]?
    public let postTestCommands: [String]?
    public let environmentVariables: [String: String]?
    public let arguments: [String]?
    public let reporters: [String]?
    
    public init(
        enabled: Bool = true,
        parallel: Bool = true,
        maxParallelism: Int? = nil,
        codeCoverage: Bool = true,
        coverageTargets: [String]? = nil,
        minimumCoverage: Double? = nil,
        testPlan: String? = nil,
        skipTests: [String]? = nil,
        onlyTests: [String]? = nil,
        destinations: [String]? = nil,
        resultBundlePath: String? = nil,
        attachments: Bool = true,
        retryCount: Int? = nil,
        timeout: Int? = nil,
        preTestCommands: [String]? = nil,
        postTestCommands: [String]? = nil,
        environmentVariables: [String: String]? = nil,
        arguments: [String]? = nil,
        reporters: [String]? = nil
    ) {
        self.enabled = enabled
        self.parallel = parallel
        self.maxParallelism = maxParallelism
        self.codeCoverage = codeCoverage
        self.coverageTargets = coverageTargets
        self.minimumCoverage = minimumCoverage
        self.testPlan = testPlan
        self.skipTests = skipTests
        self.onlyTests = onlyTests
        self.destinations = destinations
        self.resultBundlePath = resultBundlePath
        self.attachments = attachments
        self.retryCount = retryCount
        self.timeout = timeout
        self.preTestCommands = preTestCommands
        self.postTestCommands = postTestCommands
        self.environmentVariables = environmentVariables
        self.arguments = arguments
        self.reporters = reporters
    }
}

// MARK: - Deploy Configuration

/// Deployment-specific configuration
public struct DeployConfig: Codable, Sendable {
    public let targets: [DeployTargetConfig]
    public let preDeployCommands: [String]?
    public let postDeployCommands: [String]?
    public let changelog: ChangelogConfig?
    public let versionBump: VersionBumpConfig?
    public let skipWaitingForProcessing: Bool?
    public let distributeExternal: Bool?
    public let notifyTesters: Bool?
    
    public init(
        targets: [DeployTargetConfig] = [],
        preDeployCommands: [String]? = nil,
        postDeployCommands: [String]? = nil,
        changelog: ChangelogConfig? = nil,
        versionBump: VersionBumpConfig? = nil,
        skipWaitingForProcessing: Bool? = nil,
        distributeExternal: Bool? = nil,
        notifyTesters: Bool? = nil
    ) {
        self.targets = targets
        self.preDeployCommands = preDeployCommands
        self.postDeployCommands = postDeployCommands
        self.changelog = changelog
        self.versionBump = versionBump
        self.skipWaitingForProcessing = skipWaitingForProcessing
        self.distributeExternal = distributeExternal
        self.notifyTesters = notifyTesters
    }
}

/// Deploy target configuration
public struct DeployTargetConfig: Codable, Sendable {
    public let name: String
    public let type: DeployTargetType
    public let enabled: Bool
    public let apiKeyId: String?
    public let apiIssuerId: String?
    public let apiKeyPath: String?
    public let username: String?
    public let password: String?
    public let appId: String?
    public let bundleId: String?
    public let track: String?
    public let releaseStatus: String?
    public let groups: [String]?
    public let testers: [String]?
    public let metadata: [String: String]?
    
    public init(
        name: String,
        type: DeployTargetType,
        enabled: Bool = true,
        apiKeyId: String? = nil,
        apiIssuerId: String? = nil,
        apiKeyPath: String? = nil,
        username: String? = nil,
        password: String? = nil,
        appId: String? = nil,
        bundleId: String? = nil,
        track: String? = nil,
        releaseStatus: String? = nil,
        groups: [String]? = nil,
        testers: [String]? = nil,
        metadata: [String: String]? = nil
    ) {
        self.name = name
        self.type = type
        self.enabled = enabled
        self.apiKeyId = apiKeyId
        self.apiIssuerId = apiIssuerId
        self.apiKeyPath = apiKeyPath
        self.username = username
        self.password = password
        self.appId = appId
        self.bundleId = bundleId
        self.track = track
        self.releaseStatus = releaseStatus
        self.groups = groups
        self.testers = testers
        self.metadata = metadata
    }
}

/// Deploy target types
public enum DeployTargetType: String, Codable, Sendable, CaseIterable {
    case appStoreConnect = "app-store-connect"
    case testFlight = "testflight"
    case playStore = "play-store"
    case firebaseDistribution = "firebase"
    case appCenter = "app-center"
    case diawi = "diawi"
    case hockeyApp = "hockey-app"
    case s3 = "s3"
    case custom = "custom"
}

/// Changelog configuration
public struct ChangelogConfig: Codable, Sendable {
    public let enabled: Bool
    public let format: String?
    public let template: String?
    public let fromTag: String?
    public let includeCommits: Bool?
    public let includePRs: Bool?
    public let groupBy: String?
    public let outputPath: String?
    
    public init(
        enabled: Bool = true,
        format: String? = nil,
        template: String? = nil,
        fromTag: String? = nil,
        includeCommits: Bool? = nil,
        includePRs: Bool? = nil,
        groupBy: String? = nil,
        outputPath: String? = nil
    ) {
        self.enabled = enabled
        self.format = format
        self.template = template
        self.fromTag = fromTag
        self.includeCommits = includeCommits
        self.includePRs = includePRs
        self.groupBy = groupBy
        self.outputPath = outputPath
    }
}

/// Version bump configuration
public struct VersionBumpConfig: Codable, Sendable {
    public let enabled: Bool
    public let type: String?
    public let buildNumber: String?
    public let commitChanges: Bool?
    public let tagRelease: Bool?
    public let tagPrefix: String?
    public let pushChanges: Bool?
    
    public init(
        enabled: Bool = false,
        type: String? = nil,
        buildNumber: String? = nil,
        commitChanges: Bool? = nil,
        tagRelease: Bool? = nil,
        tagPrefix: String? = nil,
        pushChanges: Bool? = nil
    ) {
        self.enabled = enabled
        self.type = type
        self.buildNumber = buildNumber
        self.commitChanges = commitChanges
        self.tagRelease = tagRelease
        self.tagPrefix = tagPrefix
        self.pushChanges = pushChanges
    }
}

// MARK: - Lint Configuration

/// Linting configuration
public struct LintConfig: Codable, Sendable {
    public let enabled: Bool
    public let swiftlint: SwiftLintConfig?
    public let swiftformat: SwiftFormatConfig?
    public let eslint: ESLintConfig?
    public let ktlint: KtlintConfig?
    public let dartAnalyze: DartAnalyzeConfig?
    public let failOnWarning: Bool?
    public let autoFix: Bool?
    
    public init(
        enabled: Bool = true,
        swiftlint: SwiftLintConfig? = nil,
        swiftformat: SwiftFormatConfig? = nil,
        eslint: ESLintConfig? = nil,
        ktlint: KtlintConfig? = nil,
        dartAnalyze: DartAnalyzeConfig? = nil,
        failOnWarning: Bool? = nil,
        autoFix: Bool? = nil
    ) {
        self.enabled = enabled
        self.swiftlint = swiftlint
        self.swiftformat = swiftformat
        self.eslint = eslint
        self.ktlint = ktlint
        self.dartAnalyze = dartAnalyze
        self.failOnWarning = failOnWarning
        self.autoFix = autoFix
    }
}

/// SwiftLint configuration
public struct SwiftLintConfig: Codable, Sendable {
    public let enabled: Bool
    public let configPath: String?
    public let strict: Bool?
    public let reporter: String?
    public let quiet: Bool?
    public let paths: [String]?
    public let excludes: [String]?
    
    public init(
        enabled: Bool = true,
        configPath: String? = nil,
        strict: Bool? = nil,
        reporter: String? = nil,
        quiet: Bool? = nil,
        paths: [String]? = nil,
        excludes: [String]? = nil
    ) {
        self.enabled = enabled
        self.configPath = configPath
        self.strict = strict
        self.reporter = reporter
        self.quiet = quiet
        self.paths = paths
        self.excludes = excludes
    }
}

/// SwiftFormat configuration
public struct SwiftFormatConfig: Codable, Sendable {
    public let enabled: Bool
    public let configPath: String?
    public let lint: Bool?
    public let paths: [String]?
    public let excludes: [String]?
    
    public init(
        enabled: Bool = false,
        configPath: String? = nil,
        lint: Bool? = nil,
        paths: [String]? = nil,
        excludes: [String]? = nil
    ) {
        self.enabled = enabled
        self.configPath = configPath
        self.lint = lint
        self.paths = paths
        self.excludes = excludes
    }
}

/// ESLint configuration
public struct ESLintConfig: Codable, Sendable {
    public let enabled: Bool
    public let configPath: String?
    public let extensions: [String]?
    public let paths: [String]?
    public let fix: Bool?
    public let maxWarnings: Int?
    
    public init(
        enabled: Bool = true,
        configPath: String? = nil,
        extensions: [String]? = nil,
        paths: [String]? = nil,
        fix: Bool? = nil,
        maxWarnings: Int? = nil
    ) {
        self.enabled = enabled
        self.configPath = configPath
        self.extensions = extensions
        self.paths = paths
        self.fix = fix
        self.maxWarnings = maxWarnings
    }
}

/// Ktlint configuration
public struct KtlintConfig: Codable, Sendable {
    public let enabled: Bool
    public let android: Bool?
    public let reporter: String?
    public let paths: [String]?
    
    public init(
        enabled: Bool = true,
        android: Bool? = nil,
        reporter: String? = nil,
        paths: [String]? = nil
    ) {
        self.enabled = enabled
        self.android = android
        self.reporter = reporter
        self.paths = paths
    }
}

/// Dart analyze configuration
public struct DartAnalyzeConfig: Codable, Sendable {
    public let enabled: Bool
    public let fatalInfos: Bool?
    public let fatalWarnings: Bool?
    
    public init(
        enabled: Bool = true,
        fatalInfos: Bool? = nil,
        fatalWarnings: Bool? = nil
    ) {
        self.enabled = enabled
        self.fatalInfos = fatalInfos
        self.fatalWarnings = fatalWarnings
    }
}

// MARK: - Cache Configuration

/// Cache configuration
public struct CacheConfig: Codable, Sendable {
    public let enabled: Bool
    public let provider: CacheProvider?
    public let paths: [String]?
    public let key: String?
    public let restoreKeys: [String]?
    public let maxSize: String?
    
    public init(
        enabled: Bool = true,
        provider: CacheProvider? = nil,
        paths: [String]? = nil,
        key: String? = nil,
        restoreKeys: [String]? = nil,
        maxSize: String? = nil
    ) {
        self.enabled = enabled
        self.provider = provider
        self.paths = paths
        self.key = key
        self.restoreKeys = restoreKeys
        self.maxSize = maxSize
    }
}

/// Cache provider types
public enum CacheProvider: String, Codable, Sendable {
    case githubActions = "github-actions"
    case s3 = "s3"
    case local = "local"
    case none = "none"
}

// MARK: - Notification Configuration

/// Notification configuration
public struct NotificationConfig: Codable, Sendable {
    public let slack: SlackNotificationConfig?
    public let discord: DiscordNotificationConfig?
    public let email: EmailNotificationConfig?
    public let webhook: WebhookNotificationConfig?
    
    public init(
        slack: SlackNotificationConfig? = nil,
        discord: DiscordNotificationConfig? = nil,
        email: EmailNotificationConfig? = nil,
        webhook: WebhookNotificationConfig? = nil
    ) {
        self.slack = slack
        self.discord = discord
        self.email = email
        self.webhook = webhook
    }
}

/// Slack notification configuration
public struct SlackNotificationConfig: Codable, Sendable {
    public let enabled: Bool
    public let webhookUrl: String?
    public let channel: String?
    public let username: String?
    public let iconEmoji: String?
    public let notifyOn: [String]?
    
    public init(
        enabled: Bool = false,
        webhookUrl: String? = nil,
        channel: String? = nil,
        username: String? = nil,
        iconEmoji: String? = nil,
        notifyOn: [String]? = nil
    ) {
        self.enabled = enabled
        self.webhookUrl = webhookUrl
        self.channel = channel
        self.username = username
        self.iconEmoji = iconEmoji
        self.notifyOn = notifyOn
    }
}

/// Discord notification configuration
public struct DiscordNotificationConfig: Codable, Sendable {
    public let enabled: Bool
    public let webhookUrl: String?
    public let username: String?
    public let avatarUrl: String?
    public let notifyOn: [String]?
    
    public init(
        enabled: Bool = false,
        webhookUrl: String? = nil,
        username: String? = nil,
        avatarUrl: String? = nil,
        notifyOn: [String]? = nil
    ) {
        self.enabled = enabled
        self.webhookUrl = webhookUrl
        self.username = username
        self.avatarUrl = avatarUrl
        self.notifyOn = notifyOn
    }
}

/// Email notification configuration
public struct EmailNotificationConfig: Codable, Sendable {
    public let enabled: Bool
    public let recipients: [String]?
    public let subject: String?
    public let notifyOn: [String]?
    
    public init(
        enabled: Bool = false,
        recipients: [String]? = nil,
        subject: String? = nil,
        notifyOn: [String]? = nil
    ) {
        self.enabled = enabled
        self.recipients = recipients
        self.subject = subject
        self.notifyOn = notifyOn
    }
}

/// Webhook notification configuration
public struct WebhookNotificationConfig: Codable, Sendable {
    public let enabled: Bool
    public let url: String?
    public let method: String?
    public let headers: [String: String]?
    public let notifyOn: [String]?
    
    public init(
        enabled: Bool = false,
        url: String? = nil,
        method: String? = nil,
        headers: [String: String]? = nil,
        notifyOn: [String]? = nil
    ) {
        self.enabled = enabled
        self.url = url
        self.method = method
        self.headers = headers
        self.notifyOn = notifyOn
    }
}

// MARK: - Triggers Configuration

/// CI triggers configuration
public struct TriggersConfig: Codable, Sendable {
    public let push: PushTriggerConfig?
    public let pullRequest: PullRequestTriggerConfig?
    public let schedule: [ScheduleTriggerConfig]?
    public let manual: ManualTriggerConfig?
    public let tag: TagTriggerConfig?
    
    public init(
        push: PushTriggerConfig? = nil,
        pullRequest: PullRequestTriggerConfig? = nil,
        schedule: [ScheduleTriggerConfig]? = nil,
        manual: ManualTriggerConfig? = nil,
        tag: TagTriggerConfig? = nil
    ) {
        self.push = push
        self.pullRequest = pullRequest
        self.schedule = schedule
        self.manual = manual
        self.tag = tag
    }
}

/// Push trigger configuration
public struct PushTriggerConfig: Codable, Sendable {
    public let branches: [String]?
    public let branchesIgnore: [String]?
    public let paths: [String]?
    public let pathsIgnore: [String]?
    public let tags: [String]?
    public let tagsIgnore: [String]?
    
    public init(
        branches: [String]? = nil,
        branchesIgnore: [String]? = nil,
        paths: [String]? = nil,
        pathsIgnore: [String]? = nil,
        tags: [String]? = nil,
        tagsIgnore: [String]? = nil
    ) {
        self.branches = branches
        self.branchesIgnore = branchesIgnore
        self.paths = paths
        self.pathsIgnore = pathsIgnore
        self.tags = tags
        self.tagsIgnore = tagsIgnore
    }
}

/// Pull request trigger configuration
public struct PullRequestTriggerConfig: Codable, Sendable {
    public let branches: [String]?
    public let branchesIgnore: [String]?
    public let types: [String]?
    
    public init(
        branches: [String]? = nil,
        branchesIgnore: [String]? = nil,
        types: [String]? = nil
    ) {
        self.branches = branches
        self.branchesIgnore = branchesIgnore
        self.types = types
    }
}

/// Schedule trigger configuration
public struct ScheduleTriggerConfig: Codable, Sendable {
    public let cron: String
    public let timezone: String?
    public let name: String?
    
    public init(
        cron: String,
        timezone: String? = nil,
        name: String? = nil
    ) {
        self.cron = cron
        self.timezone = timezone
        self.name = name
    }
}

/// Manual trigger configuration
public struct ManualTriggerConfig: Codable, Sendable {
    public let enabled: Bool
    public let inputs: [ManualInputConfig]?
    
    public init(
        enabled: Bool = true,
        inputs: [ManualInputConfig]? = nil
    ) {
        self.enabled = enabled
        self.inputs = inputs
    }
}

/// Manual input configuration
public struct ManualInputConfig: Codable, Sendable {
    public let name: String
    public let description: String?
    public let required: Bool?
    public let defaultValue: String?
    public let type: String?
    public let options: [String]?
    
    public init(
        name: String,
        description: String? = nil,
        required: Bool? = nil,
        defaultValue: String? = nil,
        type: String? = nil,
        options: [String]? = nil
    ) {
        self.name = name
        self.description = description
        self.required = required
        self.defaultValue = defaultValue
        self.type = type
        self.options = options
    }
}

/// Tag trigger configuration
public struct TagTriggerConfig: Codable, Sendable {
    public let patterns: [String]?
    public let ignore: [String]?
    
    public init(
        patterns: [String]? = nil,
        ignore: [String]? = nil
    ) {
        self.patterns = patterns
        self.ignore = ignore
    }
}

// MARK: - Job Configuration

/// Job configuration
public struct JobConfig: Codable, Sendable {
    public let name: String?
    public let runsOn: String?
    public let needs: [String]?
    public let condition: String?
    public let timeout: Int?
    public let environment: [String: String]?
    public let steps: [StepConfig]?
    public let strategy: StrategyConfig?
    public let services: [String: ServiceConfig]?
    public let artifacts: ArtifactsConfig?
    
    public init(
        name: String? = nil,
        runsOn: String? = nil,
        needs: [String]? = nil,
        condition: String? = nil,
        timeout: Int? = nil,
        environment: [String: String]? = nil,
        steps: [StepConfig]? = nil,
        strategy: StrategyConfig? = nil,
        services: [String: ServiceConfig]? = nil,
        artifacts: ArtifactsConfig? = nil
    ) {
        self.name = name
        self.runsOn = runsOn
        self.needs = needs
        self.condition = condition
        self.timeout = timeout
        self.environment = environment
        self.steps = steps
        self.strategy = strategy
        self.services = services
        self.artifacts = artifacts
    }
}

/// Step configuration
public struct StepConfig: Codable, Sendable {
    public let name: String?
    public let id: String?
    public let uses: String?
    public let run: String?
    public let with: [String: String]?
    public let env: [String: String]?
    public let condition: String?
    public let continueOnError: Bool?
    public let timeout: Int?
    public let workingDirectory: String?
    public let shell: String?
    
    public init(
        name: String? = nil,
        id: String? = nil,
        uses: String? = nil,
        run: String? = nil,
        with: [String: String]? = nil,
        env: [String: String]? = nil,
        condition: String? = nil,
        continueOnError: Bool? = nil,
        timeout: Int? = nil,
        workingDirectory: String? = nil,
        shell: String? = nil
    ) {
        self.name = name
        self.id = id
        self.uses = uses
        self.run = run
        self.with = with
        self.env = env
        self.condition = condition
        self.continueOnError = continueOnError
        self.timeout = timeout
        self.workingDirectory = workingDirectory
        self.shell = shell
    }
}

/// Strategy configuration for matrix builds
public struct StrategyConfig: Codable, Sendable {
    public let matrix: [String: [String]]?
    public let failFast: Bool?
    public let maxParallel: Int?
    
    public init(
        matrix: [String: [String]]? = nil,
        failFast: Bool? = nil,
        maxParallel: Int? = nil
    ) {
        self.matrix = matrix
        self.failFast = failFast
        self.maxParallel = maxParallel
    }
}

/// Service configuration
public struct ServiceConfig: Codable, Sendable {
    public let image: String
    public let ports: [String]?
    public let env: [String: String]?
    public let options: String?
    
    public init(
        image: String,
        ports: [String]? = nil,
        env: [String: String]? = nil,
        options: String? = nil
    ) {
        self.image = image
        self.ports = ports
        self.env = env
        self.options = options
    }
}

/// Artifacts configuration
public struct ArtifactsConfig: Codable, Sendable {
    public let upload: [ArtifactUploadConfig]?
    public let download: [ArtifactDownloadConfig]?
    
    public init(
        upload: [ArtifactUploadConfig]? = nil,
        download: [ArtifactDownloadConfig]? = nil
    ) {
        self.upload = upload
        self.download = download
    }
}

/// Artifact upload configuration
public struct ArtifactUploadConfig: Codable, Sendable {
    public let name: String
    public let path: String
    public let retentionDays: Int?
    public let compressionLevel: Int?
    public let ifNoFilesFound: String?
    
    public init(
        name: String,
        path: String,
        retentionDays: Int? = nil,
        compressionLevel: Int? = nil,
        ifNoFilesFound: String? = nil
    ) {
        self.name = name
        self.path = path
        self.retentionDays = retentionDays
        self.compressionLevel = compressionLevel
        self.ifNoFilesFound = ifNoFilesFound
    }
}

/// Artifact download configuration
public struct ArtifactDownloadConfig: Codable, Sendable {
    public let name: String
    public let path: String?
    
    public init(
        name: String,
        path: String? = nil
    ) {
        self.name = name
        self.path = path
    }
}

// MARK: - Config Parser

/// Parser for MobileCI configuration files
public final class ConfigParser {
    public static let shared = ConfigParser()
    
    private let fileManager = FileManager.default
    
    public static let configFileNames = [
        "mobileci.yml",
        "mobileci.yaml",
        ".mobileci.yml",
        ".mobileci.yaml",
        "mobileci.json",
        ".mobileci.json"
    ]
    
    private init() {}
    
    // MARK: - Parsing
    
    /// Parse configuration from a file path
    public func parse(from path: String) throws -> MobileCIConfig {
        guard fileManager.fileExists(atPath: path) else {
            throw ConfigParserError.fileNotFound(path)
        }
        
        let data = try Data(contentsOf: URL(fileURLWithPath: path))
        let ext = (path as NSString).pathExtension.lowercased()
        
        switch ext {
        case "yml", "yaml":
            return try parseYAML(data)
        case "json":
            return try parseJSON(data)
        default:
            throw ConfigParserError.unsupportedFormat(ext)
        }
    }
    
    /// Find and parse configuration from default locations
    public func parseFromDefaultLocation(in directory: String) throws -> MobileCIConfig {
        for filename in Self.configFileNames {
            let path = (directory as NSString).appendingPathComponent(filename)
            if fileManager.fileExists(atPath: path) {
                return try parse(from: path)
            }
        }
        
        throw ConfigParserError.configNotFound(directory)
    }
    
    /// Parse YAML configuration
    private func parseYAML(_ data: Data) throws -> MobileCIConfig {
        guard let string = String(data: data, encoding: .utf8) else {
            throw ConfigParserError.invalidEncoding
        }
        
        do {
            let decoder = YAMLDecoder()
            return try decoder.decode(MobileCIConfig.self, from: string)
        } catch {
            throw ConfigParserError.parseError(error.localizedDescription)
        }
    }
    
    /// Parse JSON configuration
    private func parseJSON(_ data: Data) throws -> MobileCIConfig {
        do {
            let decoder = JSONDecoder()
            decoder.keyDecodingStrategy = .convertFromSnakeCase
            return try decoder.decode(MobileCIConfig.self, from: data)
        } catch {
            throw ConfigParserError.parseError(error.localizedDescription)
        }
    }
    
    // MARK: - Validation
    
    /// Validate a configuration
    public func validate(_ config: MobileCIConfig) throws {
        var errors: [String] = []
        
        // Validate version
        if config.version.isEmpty {
            errors.append("Configuration version is required")
        }
        
        // Validate name
        if config.name.isEmpty {
            errors.append("Project name is required")
        }
        
        // Validate platforms
        for platformConfig in config.platforms {
            if platformConfig.enabled {
                // Validate iOS/macOS specific
                if [.ios, .macos, .watchos, .tvos, .visionos].contains(platformConfig.platform) {
                    if platformConfig.project == nil && platformConfig.workspace == nil && platformConfig.packagePath == nil {
                        errors.append("\(platformConfig.platform.displayName): project, workspace, or package path is required")
                    }
                    
                    if platformConfig.scheme == nil && platformConfig.target == nil {
                        errors.append("\(platformConfig.platform.displayName): scheme or target is required")
                    }
                }
            }
        }
        
        // Validate deploy targets
        if let deploy = config.deploy {
            for target in deploy.targets {
                if target.enabled && target.type == .appStoreConnect {
                    if target.apiKeyId == nil && target.username == nil {
                        errors.append("App Store Connect deployment requires API key or username")
                    }
                }
            }
        }
        
        if !errors.isEmpty {
            throw ConfigParserError.validationFailed(errors)
        }
    }
    
    // MARK: - Generation
    
    /// Generate a default configuration
    public func generateDefault(for platform: Platform, name: String) -> MobileCIConfig {
        let platformConfig = PlatformConfig(
            platform: platform,
            enabled: true,
            scheme: name
        )
        
        let buildConfig = BuildConfig(
            clean: true,
            parallel: true,
            xcpretty: true,
            generateDSYM: true
        )
        
        let testConfig = TestConfig(
            enabled: true,
            parallel: true,
            codeCoverage: true
        )
        
        let lintConfig = LintConfig(
            enabled: true,
            swiftlint: SwiftLintConfig(enabled: true),
            failOnWarning: false
        )
        
        let cacheConfig = CacheConfig(
            enabled: true,
            provider: .githubActions
        )
        
        let triggers = TriggersConfig(
            push: PushTriggerConfig(branches: ["main", "develop"]),
            pullRequest: PullRequestTriggerConfig(branches: ["main"])
        )
        
        return MobileCIConfig(
            version: "1.0",
            name: name,
            platforms: [platformConfig],
            build: buildConfig,
            test: testConfig,
            lint: lintConfig,
            cache: cacheConfig,
            triggers: triggers
        )
    }
    
    /// Write configuration to a file
    public func write(_ config: MobileCIConfig, to path: String, format: ConfigFormat = .yaml) throws {
        let data: Data
        
        switch format {
        case .yaml:
            let encoder = YAMLEncoder()
            let string = try encoder.encode(config)
            guard let encoded = string.data(using: .utf8) else {
                throw ConfigParserError.invalidEncoding
            }
            data = encoded
        case .json:
            let encoder = JSONEncoder()
            encoder.keyEncodingStrategy = .convertToSnakeCase
            encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
            data = try encoder.encode(config)
        }
        
        try data.write(to: URL(fileURLWithPath: path))
    }
}

/// Configuration file formats
public enum ConfigFormat: String, CaseIterable {
    case yaml
    case json
}

// MARK: - Config Parser Errors

/// Errors that can occur during configuration parsing
public enum ConfigParserError: LocalizedError {
    case fileNotFound(String)
    case configNotFound(String)
    case unsupportedFormat(String)
    case invalidEncoding
    case parseError(String)
    case validationFailed([String])
    
    public var errorDescription: String? {
        switch self {
        case .fileNotFound(let path):
            return "Configuration file not found: \(path)"
        case .configNotFound(let directory):
            return "No configuration file found in: \(directory)"
        case .unsupportedFormat(let format):
            return "Unsupported configuration format: \(format)"
        case .invalidEncoding:
            return "Invalid file encoding (expected UTF-8)"
        case .parseError(let message):
            return "Failed to parse configuration: \(message)"
        case .validationFailed(let errors):
            return "Configuration validation failed:\n- " + errors.joined(separator: "\n- ")
        }
    }
}
