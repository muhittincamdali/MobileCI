// CIWorkflowGenerator.swift
// MobileCIKit
//
// Generates CI/CD workflow configurations for multiple platforms.
// Supports GitHub Actions, GitLab CI, Bitrise, CircleCI, and Jenkins.

import Foundation
import Yams

// MARK: - CI Provider

/// Supported CI/CD providers
public enum CIProvider: String, CaseIterable, Codable, Sendable {
    case githubActions = "github-actions"
    case gitlabCI = "gitlab-ci"
    case bitrise = "bitrise"
    case circleCI = "circleci"
    case jenkins = "jenkins"
    case azurePipelines = "azure-pipelines"
    case travisCI = "travis-ci"
    
    public var displayName: String {
        switch self {
        case .githubActions: return "GitHub Actions"
        case .gitlabCI: return "GitLab CI"
        case .bitrise: return "Bitrise"
        case .circleCI: return "CircleCI"
        case .jenkins: return "Jenkins"
        case .azurePipelines: return "Azure Pipelines"
        case .travisCI: return "Travis CI"
        }
    }
    
    public var configFileName: String {
        switch self {
        case .githubActions: return "ios.yml"
        case .gitlabCI: return ".gitlab-ci.yml"
        case .bitrise: return "bitrise.yml"
        case .circleCI: return "config.yml"
        case .jenkins: return "Jenkinsfile"
        case .azurePipelines: return "azure-pipelines.yml"
        case .travisCI: return ".travis.yml"
        }
    }
    
    public var configPath: String {
        switch self {
        case .githubActions: return ".github/workflows/\(configFileName)"
        case .circleCI: return ".circleci/\(configFileName)"
        default: return configFileName
        }
    }
}

// MARK: - Workflow Configuration

/// Configuration for generating CI workflows
public struct WorkflowConfig: Codable, Sendable {
    public var projectName: String
    public var platform: Platform
    public var scheme: String?
    public var workspace: String?
    public var project: String?
    public var buildConfiguration: String
    public var testDestination: String
    public var deployTarget: DeployTarget?
    public var xcodeVersion: String
    public var swiftVersion: String?
    public var rubyVersion: String?
    public var nodeVersion: String?
    public var flutterVersion: String?
    public var enableCache: Bool
    public var enableLinting: Bool
    public var enableTesting: Bool
    public var enableCoverage: Bool
    public var enableCodeSigning: Bool
    public var enableNotifications: Bool
    public var slackWebhook: String?
    public var parallelTesting: Bool
    public var matrixTesting: Bool
    public var environments: [String]
    
    public static let `default` = WorkflowConfig(
        projectName: "App",
        platform: .ios,
        scheme: nil,
        workspace: nil,
        project: nil,
        buildConfiguration: "Release",
        testDestination: "platform=iOS Simulator,name=iPhone 15 Pro,OS=17.0",
        deployTarget: nil,
        xcodeVersion: "16.0",
        swiftVersion: "5.9",
        rubyVersion: "3.2",
        nodeVersion: "20",
        flutterVersion: "3.24.0",
        enableCache: true,
        enableLinting: true,
        enableTesting: true,
        enableCoverage: true,
        enableCodeSigning: false,
        enableNotifications: false,
        slackWebhook: nil,
        parallelTesting: false,
        matrixTesting: false,
        environments: ["development", "staging", "production"]
    )
    
    public init(
        projectName: String = "App",
        platform: Platform = .ios,
        scheme: String? = nil,
        workspace: String? = nil,
        project: String? = nil,
        buildConfiguration: String = "Release",
        testDestination: String = "platform=iOS Simulator,name=iPhone 15 Pro,OS=17.0",
        deployTarget: DeployTarget? = nil,
        xcodeVersion: String = "16.0",
        swiftVersion: String? = "5.9",
        rubyVersion: String? = "3.2",
        nodeVersion: String? = "20",
        flutterVersion: String? = "3.24.0",
        enableCache: Bool = true,
        enableLinting: Bool = true,
        enableTesting: Bool = true,
        enableCoverage: Bool = true,
        enableCodeSigning: Bool = false,
        enableNotifications: Bool = false,
        slackWebhook: String? = nil,
        parallelTesting: Bool = false,
        matrixTesting: Bool = false,
        environments: [String] = ["development", "staging", "production"]
    ) {
        self.projectName = projectName
        self.platform = platform
        self.scheme = scheme
        self.workspace = workspace
        self.project = project
        self.buildConfiguration = buildConfiguration
        self.testDestination = testDestination
        self.deployTarget = deployTarget
        self.xcodeVersion = xcodeVersion
        self.swiftVersion = swiftVersion
        self.rubyVersion = rubyVersion
        self.nodeVersion = nodeVersion
        self.flutterVersion = flutterVersion
        self.enableCache = enableCache
        self.enableLinting = enableLinting
        self.enableTesting = enableTesting
        self.enableCoverage = enableCoverage
        self.enableCodeSigning = enableCodeSigning
        self.enableNotifications = enableNotifications
        self.slackWebhook = slackWebhook
        self.parallelTesting = parallelTesting
        self.matrixTesting = matrixTesting
        self.environments = environments
    }
}

// MARK: - Deploy Target

/// Deployment target configuration
public enum DeployTarget: String, Codable, Sendable {
    case testflight = "testflight"
    case appStore = "appstore"
    case firebase = "firebase"
    case appcenter = "appcenter"
    case playStore = "playstore"
    case playStoreInternal = "playstore-internal"
    case s3 = "s3"
    case custom = "custom"
}

// MARK: - Workflow Generator

/// Generates CI/CD workflow configurations
public final class CIWorkflowGenerator: @unchecked Sendable {
    public static let shared = CIWorkflowGenerator()
    
    private let fileManager = FileManager.default
    private let logger = Logger.shared
    
    private init() {}
    
    // MARK: - Generation
    
    /// Generate workflow for specified provider
    public func generateWorkflow(
        provider: CIProvider,
        config: WorkflowConfig
    ) throws -> String {
        switch provider {
        case .githubActions:
            return generateGitHubActions(config: config)
        case .gitlabCI:
            return generateGitLabCI(config: config)
        case .bitrise:
            return generateBitrise(config: config)
        case .circleCI:
            return generateCircleCI(config: config)
        case .jenkins:
            return generateJenkinsfile(config: config)
        case .azurePipelines:
            return generateAzurePipelines(config: config)
        case .travisCI:
            return generateTravisCI(config: config)
        }
    }
    
    /// Save workflow to file
    public func saveWorkflow(
        provider: CIProvider,
        config: WorkflowConfig,
        basePath: String = "."
    ) throws {
        let content = try generateWorkflow(provider: provider, config: config)
        let path = "\(basePath)/\(provider.configPath)"
        
        // Create directory if needed
        let directory = (path as NSString).deletingLastPathComponent
        if !fileManager.fileExists(atPath: directory) {
            try fileManager.createDirectory(atPath: directory, withIntermediateDirectories: true)
        }
        
        try content.write(toFile: path, atomically: true, encoding: .utf8)
        logger.success("Generated \(provider.displayName) workflow: \(path)")
    }
    
    /// Generate workflows for all providers
    public func generateAllWorkflows(
        config: WorkflowConfig,
        providers: [CIProvider] = CIProvider.allCases,
        basePath: String = "."
    ) throws {
        for provider in providers {
            try saveWorkflow(provider: provider, config: config, basePath: basePath)
        }
    }
    
    // MARK: - GitHub Actions
    
    private func generateGitHubActions(config: WorkflowConfig) -> String {
        let schemeName = config.scheme ?? config.projectName
        let workspaceArg = config.workspace.map { "-workspace '\($0)'" } ?? ""
        let projectArg = config.project.map { "-project '\($0)'" } ?? ""
        let xcodebuildProject = workspaceArg.isEmpty ? projectArg : workspaceArg
        
        var workflow = """
            name: iOS CI
            
            on:
              push:
                branches: [main, develop]
              pull_request:
                branches: [main]
              workflow_dispatch:
            
            env:
              SCHEME: '\(schemeName)'
              CONFIGURATION: '\(config.buildConfiguration)'
              DESTINATION: '\(config.testDestination)'
            
            concurrency:
              group: ${{ github.workflow }}-${{ github.ref }}
              cancel-in-progress: true
            
            jobs:
            """
        
        // Build and Test Job
        workflow += """
            
              build-and-test:
                name: Build & Test
                runs-on: macos-14
                timeout-minutes: 30
            
                steps:
                  - name: Checkout
                    uses: actions/checkout@v4
                    with:
                      fetch-depth: 0
            
                  - name: Setup Xcode
                    uses: maxim-lobanov/setup-xcode@v1
                    with:
                      xcode-version: '\(config.xcodeVersion)'
            
            """
        
        // Cache
        if config.enableCache {
            workflow += """
                
                      - name: Cache SPM
                        uses: actions/cache@v4
                        with:
                          path: |
                            ~/Library/Developer/Xcode/DerivedData/**/SourcePackages
                            .build
                          key: ${{ runner.os }}-spm-${{ hashFiles('**/Package.resolved') }}
                          restore-keys: |
                            ${{ runner.os }}-spm-
                
                """
        }
        
        // Linting
        if config.enableLinting {
            workflow += """
                
                      - name: Install SwiftLint
                        run: brew install swiftlint
                
                      - name: Lint
                        run: swiftlint lint --reporter github-actions-logging
                
                """
        }
        
        // Build
        workflow += """
            
                  - name: Build
                    run: |
                      set -o pipefail
                      xcodebuild build-for-testing \\
                        \(xcodebuildProject) \\
                        -scheme "$SCHEME" \\
                        -configuration "$CONFIGURATION" \\
                        -destination "$DESTINATION" \\
                        -derivedDataPath DerivedData \\
                        | xcpretty --color
            
            """
        
        // Testing
        if config.enableTesting {
            workflow += """
                
                      - name: Test
                        run: |
                          set -o pipefail
                          xcodebuild test-without-building \\
                            \(xcodebuildProject) \\
                            -scheme "$SCHEME" \\
                            -destination "$DESTINATION" \\
                            -derivedDataPath DerivedData \\
                            -resultBundlePath TestResults.xcresult \\
                            \(config.parallelTesting ? "-parallel-testing-enabled YES \\" : "")
                            | xcpretty --color
                
                      - name: Upload Test Results
                        uses: actions/upload-artifact@v4
                        if: always()
                        with:
                          name: test-results
                          path: TestResults.xcresult
                          retention-days: 14
                
                """
        }
        
        // Coverage
        if config.enableCoverage {
            workflow += """
                
                      - name: Code Coverage
                        run: |
                          xcrun xccov view --report --json TestResults.xcresult > coverage.json
                
                      - name: Upload Coverage
                        uses: codecov/codecov-action@v4
                        with:
                          files: coverage.json
                          fail_ci_if_error: false
                
                """
        }
        
        // Deployment Job
        if let deployTarget = config.deployTarget {
            workflow += generateGitHubActionsDeployJob(config: config, target: deployTarget)
        }
        
        return workflow
    }
    
    private func generateGitHubActionsDeployJob(config: WorkflowConfig, target: DeployTarget) -> String {
        let schemeName = config.scheme ?? config.projectName
        
        var job = """
            
              deploy:
                name: Deploy to \(target.rawValue.capitalized)
                needs: build-and-test
                runs-on: macos-14
                if: github.ref == 'refs/heads/main' || startsWith(github.ref, 'refs/tags/')
            
                steps:
                  - name: Checkout
                    uses: actions/checkout@v4
            
                  - name: Setup Xcode
                    uses: maxim-lobanov/setup-xcode@v1
                    with:
                      xcode-version: '\(config.xcodeVersion)'
            
            """
        
        if config.enableCodeSigning {
            job += """
                
                      - name: Install Certificate
                        env:
                          P12_CERTIFICATE: ${{ secrets.P12_CERTIFICATE }}
                          P12_PASSWORD: ${{ secrets.P12_PASSWORD }}
                          KEYCHAIN_PASSWORD: ${{ secrets.KEYCHAIN_PASSWORD }}
                        run: |
                          KEYCHAIN_PATH=$RUNNER_TEMP/app-signing.keychain-db
                          
                          echo $P12_CERTIFICATE | base64 --decode > certificate.p12
                          
                          security create-keychain -p "$KEYCHAIN_PASSWORD" $KEYCHAIN_PATH
                          security set-keychain-settings -lut 21600 $KEYCHAIN_PATH
                          security unlock-keychain -p "$KEYCHAIN_PASSWORD" $KEYCHAIN_PATH
                          
                          security import certificate.p12 -P "$P12_PASSWORD" -A -t cert -f pkcs12 -k $KEYCHAIN_PATH
                          security list-keychain -d user -s $KEYCHAIN_PATH
                
                      - name: Install Provisioning Profile
                        env:
                          PROVISIONING_PROFILE: ${{ secrets.PROVISIONING_PROFILE }}
                        run: |
                          PP_PATH=$RUNNER_TEMP/profile.mobileprovision
                          echo $PROVISIONING_PROFILE | base64 --decode > $PP_PATH
                          
                          mkdir -p ~/Library/MobileDevice/Provisioning\\ Profiles
                          cp $PP_PATH ~/Library/MobileDevice/Provisioning\\ Profiles/
                
                """
        }
        
        // Archive and Export
        job += """
            
                  - name: Build Archive
                    run: |
                      xcodebuild archive \\
                        -scheme "\(schemeName)" \\
                        -configuration Release \\
                        -archivePath build/\(schemeName).xcarchive \\
                        -destination 'generic/platform=iOS' \\
                        -allowProvisioningUpdates
            
                  - name: Export IPA
                    run: |
                      xcodebuild -exportArchive \\
                        -archivePath build/\(schemeName).xcarchive \\
                        -exportPath build/export \\
                        -exportOptionsPlist ExportOptions.plist
            
            """
        
        // Deploy based on target
        switch target {
        case .testflight:
            job += """
                
                      - name: Upload to TestFlight
                        env:
                          ASC_KEY_ID: ${{ secrets.ASC_KEY_ID }}
                          ASC_ISSUER_ID: ${{ secrets.ASC_ISSUER_ID }}
                          ASC_KEY_CONTENT: ${{ secrets.ASC_KEY_CONTENT }}
                        run: |
                          xcrun altool --upload-app \\
                            --type ios \\
                            --file build/export/\(schemeName).ipa \\
                            --apiKey "$ASC_KEY_ID" \\
                            --apiIssuer "$ASC_ISSUER_ID"
                
                """
            
        case .firebase:
            job += """
                
                      - name: Upload to Firebase
                        uses: wzieba/Firebase-Distribution-Github-Action@v1
                        with:
                          appId: ${{ secrets.FIREBASE_APP_ID }}
                          serviceCredentialsFileContent: ${{ secrets.FIREBASE_CREDENTIALS }}
                          groups: testers
                          file: build/export/\(schemeName).ipa
                
                """
            
        default:
            break
        }
        
        return job
    }
    
    // MARK: - GitLab CI
    
    private func generateGitLabCI(config: WorkflowConfig) -> String {
        let schemeName = config.scheme ?? config.projectName
        
        var workflow = """
            stages:
              - build
              - test
              - deploy
            
            variables:
              SCHEME: '\(schemeName)'
              CONFIGURATION: '\(config.buildConfiguration)'
              LC_ALL: 'en_US.UTF-8'
              LANG: 'en_US.UTF-8'
            
            .macos-runner:
              tags:
                - macos
                - xcode-\(config.xcodeVersion)
            
            """
        
        if config.enableCache {
            workflow += """
                
                cache:
                  key: ${CI_COMMIT_REF_SLUG}
                  paths:
                    - .build/
                    - ~/Library/Developer/Xcode/DerivedData/
                
                """
        }
        
        // Build job
        workflow += """
            
            build:
              extends: .macos-runner
              stage: build
              script:
                - xcodebuild build \\
                    -scheme "$SCHEME" \\
                    -configuration "$CONFIGURATION" \\
                    -destination 'platform=iOS Simulator,name=iPhone 15 Pro' \\
                    -derivedDataPath DerivedData \\
                    | xcpretty
              artifacts:
                paths:
                  - DerivedData/
                expire_in: 1 day
            
            """
        
        if config.enableTesting {
            workflow += """
                
                test:
                  extends: .macos-runner
                  stage: test
                  dependencies:
                    - build
                  script:
                    - xcodebuild test \\
                        -scheme "$SCHEME" \\
                        -destination 'platform=iOS Simulator,name=iPhone 15 Pro' \\
                        -derivedDataPath DerivedData \\
                        -resultBundlePath TestResults.xcresult \\
                        | xcpretty
                  artifacts:
                    paths:
                      - TestResults.xcresult
                    reports:
                      junit: TestResults.xml
                    when: always
                
                """
        }
        
        if config.deployTarget != nil {
            workflow += """
                
                deploy:
                  extends: .macos-runner
                  stage: deploy
                  only:
                    - main
                    - tags
                  script:
                    - xcodebuild archive \\
                        -scheme "$SCHEME" \\
                        -configuration Release \\
                        -archivePath build/$SCHEME.xcarchive \\
                        -destination 'generic/platform=iOS'
                    - xcodebuild -exportArchive \\
                        -archivePath build/$SCHEME.xcarchive \\
                        -exportPath build/export \\
                        -exportOptionsPlist ExportOptions.plist
                  artifacts:
                    paths:
                      - build/export/
                    expire_in: 1 week
                
                """
        }
        
        return workflow
    }
    
    // MARK: - Bitrise
    
    private func generateBitrise(config: WorkflowConfig) -> String {
        let schemeName = config.scheme ?? config.projectName
        
        return """
            format_version: '11'
            default_step_lib_source: https://github.com/bitrise-io/bitrise-steplib.git
            
            project_type: ios
            
            app:
              envs:
                - SCHEME: \(schemeName)
                - CONFIGURATION: \(config.buildConfiguration)
                - XCODE_VERSION: \(config.xcodeVersion)
            
            trigger_map:
              - push_branch: main
                workflow: primary
              - pull_request_source_branch: '*'
                workflow: primary
              - tag: '*'
                workflow: deploy
            
            workflows:
              primary:
                steps:
                  - activate-ssh-key@4:
                      run_if: '{{getenv "SSH_RSA_PRIVATE_KEY" | ne ""}}'
                  - git-clone@8: {}
                  - cache-pull@2: {}
                  - xcode-test@5:
                      inputs:
                        - scheme: $SCHEME
                        - configuration: Debug
                        - simulator_device: iPhone 15 Pro
                  - cache-push@2: {}
                  - deploy-to-bitrise-io@2: {}
            
              deploy:
                steps:
                  - activate-ssh-key@4: {}
                  - git-clone@8: {}
                  - certificate-and-profile-installer@1: {}
                  - xcode-archive@5:
                      inputs:
                        - scheme: $SCHEME
                        - configuration: $CONFIGURATION
                        - export_method: app-store
                  - deploy-to-itunesconnect-application-loader@1:
                      inputs:
                        - password: $APPLE_ID_PASSWORD
                        - app_password: $APP_SPECIFIC_PASSWORD
                        - itunescon_user: $APPLE_ID
            """
    }
    
    // MARK: - CircleCI
    
    private func generateCircleCI(config: WorkflowConfig) -> String {
        let schemeName = config.scheme ?? config.projectName
        
        return """
            version: 2.1
            
            orbs:
              macos: circleci/macos@2
            
            parameters:
              xcode_version:
                type: string
                default: '\(config.xcodeVersion)'
            
            jobs:
              build-and-test:
                macos:
                  xcode: << pipeline.parameters.xcode_version >>
                resource_class: macos.m1.medium.gen1
                
                environment:
                  SCHEME: \(schemeName)
                  CONFIGURATION: \(config.buildConfiguration)
                
                steps:
                  - checkout
                  
                  - restore_cache:
                      keys:
                        - spm-{{ checksum "Package.resolved" }}
                        - spm-
                  
                  - run:
                      name: Build
                      command: |
                        xcodebuild build-for-testing \\
                          -scheme "$SCHEME" \\
                          -destination 'platform=iOS Simulator,name=iPhone 15 Pro' \\
                          -derivedDataPath DerivedData \\
                          | xcpretty
                  
                  - run:
                      name: Test
                      command: |
                        xcodebuild test-without-building \\
                          -scheme "$SCHEME" \\
                          -destination 'platform=iOS Simulator,name=iPhone 15 Pro' \\
                          -derivedDataPath DerivedData \\
                          -resultBundlePath TestResults.xcresult \\
                          | xcpretty
                  
                  - save_cache:
                      key: spm-{{ checksum "Package.resolved" }}
                      paths:
                        - DerivedData/SourcePackages
                  
                  - store_test_results:
                      path: TestResults.xcresult
                  
                  - store_artifacts:
                      path: TestResults.xcresult
            
              deploy:
                macos:
                  xcode: << pipeline.parameters.xcode_version >>
                resource_class: macos.m1.medium.gen1
                
                steps:
                  - checkout
                  - run:
                      name: Archive
                      command: |
                        xcodebuild archive \\
                          -scheme "\(schemeName)" \\
                          -configuration Release \\
                          -archivePath build/\(schemeName).xcarchive \\
                          -destination 'generic/platform=iOS'
                  - run:
                      name: Export
                      command: |
                        xcodebuild -exportArchive \\
                          -archivePath build/\(schemeName).xcarchive \\
                          -exportPath build/export \\
                          -exportOptionsPlist ExportOptions.plist
                  - store_artifacts:
                      path: build/export
            
            workflows:
              version: 2
              build-test-deploy:
                jobs:
                  - build-and-test
                  - deploy:
                      requires:
                        - build-and-test
                      filters:
                        branches:
                          only: main
            """
    }
    
    // MARK: - Jenkins
    
    private func generateJenkinsfile(config: WorkflowConfig) -> String {
        let schemeName = config.scheme ?? config.projectName
        
        return """
            pipeline {
                agent {
                    label 'macos && xcode-\(config.xcodeVersion)'
                }
                
                environment {
                    SCHEME = '\(schemeName)'
                    CONFIGURATION = '\(config.buildConfiguration)'
                    LANG = 'en_US.UTF-8'
                    LC_ALL = 'en_US.UTF-8'
                }
                
                options {
                    timeout(time: 30, unit: 'MINUTES')
                    disableConcurrentBuilds()
                    buildDiscarder(logRotator(numToKeepStr: '10'))
                }
                
                stages {
                    stage('Checkout') {
                        steps {
                            checkout scm
                        }
                    }
                    
                    stage('Build') {
                        steps {
                            sh '''
                                xcodebuild build \\
                                    -scheme "${SCHEME}" \\
                                    -configuration "${CONFIGURATION}" \\
                                    -destination 'platform=iOS Simulator,name=iPhone 15 Pro' \\
                                    -derivedDataPath DerivedData \\
                                    | xcpretty
                            '''
                        }
                    }
                    
                    stage('Test') {
                        steps {
                            sh '''
                                xcodebuild test \\
                                    -scheme "${SCHEME}" \\
                                    -destination 'platform=iOS Simulator,name=iPhone 15 Pro' \\
                                    -derivedDataPath DerivedData \\
                                    -resultBundlePath TestResults.xcresult \\
                                    | xcpretty
                            '''
                        }
                        post {
                            always {
                                junit 'TestResults.xml'
                            }
                        }
                    }
                    
                    stage('Deploy') {
                        when {
                            anyOf {
                                branch 'main'
                                buildingTag()
                            }
                        }
                        steps {
                            sh '''
                                xcodebuild archive \\
                                    -scheme "${SCHEME}" \\
                                    -configuration Release \\
                                    -archivePath build/${SCHEME}.xcarchive \\
                                    -destination 'generic/platform=iOS'
                                
                                xcodebuild -exportArchive \\
                                    -archivePath build/${SCHEME}.xcarchive \\
                                    -exportPath build/export \\
                                    -exportOptionsPlist ExportOptions.plist
                            '''
                        }
                        post {
                            success {
                                archiveArtifacts artifacts: 'build/export/*.ipa', fingerprint: true
                            }
                        }
                    }
                }
                
                post {
                    always {
                        cleanWs()
                    }
                    failure {
                        mail to: 'team@example.com',
                             subject: "Failed Pipeline: ${currentBuild.fullDisplayName}",
                             body: "Something is wrong with ${env.BUILD_URL}"
                    }
                }
            }
            """
    }
    
    // MARK: - Azure Pipelines
    
    private func generateAzurePipelines(config: WorkflowConfig) -> String {
        let schemeName = config.scheme ?? config.projectName
        
        return """
            trigger:
              branches:
                include:
                  - main
                  - develop
              tags:
                include:
                  - v*
            
            pr:
              branches:
                include:
                  - main
            
            pool:
              vmImage: 'macos-latest'
            
            variables:
              SCHEME: '\(schemeName)'
              CONFIGURATION: '\(config.buildConfiguration)'
              XCODE_VERSION: '\(config.xcodeVersion)'
            
            stages:
              - stage: Build
                jobs:
                  - job: BuildAndTest
                    displayName: 'Build & Test'
                    timeoutInMinutes: 30
                    
                    steps:
                      - task: UseRubyVersion@0
                        inputs:
                          versionSpec: '>= 3.0'
                      
                      - script: |
                          sudo xcode-select -s /Applications/Xcode_$(XCODE_VERSION).app
                        displayName: 'Select Xcode $(XCODE_VERSION)'
                      
                      - task: Cache@2
                        inputs:
                          key: 'spm | "$(Agent.OS)" | **/Package.resolved'
                          path: $(Build.SourcesDirectory)/DerivedData/SourcePackages
                        displayName: 'Cache SPM'
                      
                      - script: |
                          xcodebuild build-for-testing \\
                            -scheme "$(SCHEME)" \\
                            -configuration "$(CONFIGURATION)" \\
                            -destination 'platform=iOS Simulator,name=iPhone 15 Pro' \\
                            -derivedDataPath DerivedData \\
                            | xcpretty
                        displayName: 'Build'
                      
                      - script: |
                          xcodebuild test-without-building \\
                            -scheme "$(SCHEME)" \\
                            -destination 'platform=iOS Simulator,name=iPhone 15 Pro' \\
                            -derivedDataPath DerivedData \\
                            -resultBundlePath $(Build.ArtifactStagingDirectory)/TestResults.xcresult \\
                            | xcpretty
                        displayName: 'Test'
                      
                      - task: PublishTestResults@2
                        inputs:
                          testResultsFormat: 'JUnit'
                          testResultsFiles: '**/TestResults.xml'
                        condition: always()
              
              - stage: Deploy
                condition: and(succeeded(), eq(variables['Build.SourceBranch'], 'refs/heads/main'))
                jobs:
                  - deployment: DeployToTestFlight
                    displayName: 'Deploy to TestFlight'
                    environment: 'production'
                    strategy:
                      runOnce:
                        deploy:
                          steps:
                            - checkout: self
                            - script: |
                                xcodebuild archive \\
                                  -scheme "$(SCHEME)" \\
                                  -configuration Release \\
                                  -archivePath build/$(SCHEME).xcarchive \\
                                  -destination 'generic/platform=iOS'
                              displayName: 'Archive'
            """
    }
    
    // MARK: - Travis CI
    
    private func generateTravisCI(config: WorkflowConfig) -> String {
        let schemeName = config.scheme ?? config.projectName
        
        return """
            language: swift
            os: osx
            osx_image: xcode\(config.xcodeVersion.replacingOccurrences(of: ".", with: "_"))
            
            env:
              global:
                - SCHEME='\(schemeName)'
                - CONFIGURATION='\(config.buildConfiguration)'
            
            cache:
              directories:
                - DerivedData/SourcePackages
            
            stages:
              - build
              - test
              - deploy
            
            jobs:
              include:
                - stage: build
                  script:
                    - set -o pipefail
                    - xcodebuild build
                        -scheme "$SCHEME"
                        -configuration "$CONFIGURATION"
                        -destination 'platform=iOS Simulator,name=iPhone 15 Pro'
                        -derivedDataPath DerivedData
                        | xcpretty
                
                - stage: test
                  script:
                    - set -o pipefail
                    - xcodebuild test
                        -scheme "$SCHEME"
                        -destination 'platform=iOS Simulator,name=iPhone 15 Pro'
                        -derivedDataPath DerivedData
                        -resultBundlePath TestResults.xcresult
                        | xcpretty
                
                - stage: deploy
                  if: branch = main
                  script:
                    - xcodebuild archive
                        -scheme "$SCHEME"
                        -configuration Release
                        -archivePath build/$SCHEME.xcarchive
                        -destination 'generic/platform=iOS'
            """
    }
}
