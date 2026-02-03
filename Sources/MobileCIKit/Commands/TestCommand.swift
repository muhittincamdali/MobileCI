// TestCommand.swift
// MobileCIKit
//
// Test command implementation for mobile applications.

import Foundation
import ArgumentParser

/// Command for running tests on mobile applications
public struct TestCommand: AsyncParsableCommand {
    public static let configuration = CommandConfiguration(
        commandName: "test",
        abstract: "Run tests for mobile applications",
        discussion: """
            Run unit tests, UI tests, integration tests, and more for iOS, Android,
            Flutter, and React Native applications with support for code coverage,
            parallel execution, and multiple reporters.
            
            EXAMPLES:
              mobileci test --platform ios --scheme MyAppTests
              mobileci test --platform flutter --coverage
              mobileci test --platform android --module app
              mobileci test --platform ios --test-plan MyTestPlan
            """
    )
    
    // MARK: - Options
    
    @Option(name: .shortAndLong, help: "Target platform (ios, android, flutter, react-native)")
    var platform: Platform = .ios
    
    @Option(name: .long, help: "Xcode scheme to test")
    var scheme: String?
    
    @Option(name: .long, help: "Xcode project file (.xcodeproj)")
    var project: String?
    
    @Option(name: .long, help: "Xcode workspace file (.xcworkspace)")
    var workspace: String?
    
    @Option(name: .long, help: "Swift package path")
    var package: String?
    
    @Option(name: .long, help: "Test plan for Xcode testing")
    var testPlan: String?
    
    @Option(name: .long, help: "Test destination")
    var destination: String?
    
    @Option(name: .long, help: "Test target or module")
    var target: String?
    
    @Option(name: .long, help: "Result bundle path")
    var resultBundlePath: String?
    
    @Option(name: .long, help: "Output directory for results")
    var output: String?
    
    @Option(name: .long, help: "Specific test classes to run", parsing: .upToNextOption)
    var onlyTests: [String] = []
    
    @Option(name: .long, help: "Test classes to skip", parsing: .upToNextOption)
    var skipTests: [String] = []
    
    @Option(name: .long, help: "Test reporter format (junit, html, json, xcresult)")
    var reporter: TestReporter = .xcresult
    
    @Option(name: .long, help: "Minimum code coverage percentage")
    var minimumCoverage: Double?
    
    @Option(name: .long, help: "Maximum parallel test runners")
    var maxParallelism: Int?
    
    @Option(name: .long, help: "Test timeout in seconds")
    var timeout: Int?
    
    @Option(name: .long, help: "Number of test retries on failure")
    var retryCount: Int?
    
    @Option(name: .long, help: "Additional test arguments", parsing: .upToNextOption)
    var testArgs: [String] = []
    
    @Option(name: .long, help: "Environment variables (KEY=VALUE)", parsing: .upToNextOption)
    var env: [String] = []
    
    // MARK: - Flags
    
    @Flag(name: .long, help: "Enable code coverage collection")
    var coverage: Bool = false
    
    @Flag(name: .long, help: "Run tests in parallel")
    var parallel: Bool = false
    
    @Flag(name: .long, help: "Run only unit tests")
    var unitOnly: Bool = false
    
    @Flag(name: .long, help: "Run only UI tests")
    var uiOnly: Bool = false
    
    @Flag(name: .long, help: "Run only integration tests")
    var integrationOnly: Bool = false
    
    @Flag(name: .long, help: "Build before testing")
    var buildForTesting: Bool = false
    
    @Flag(name: .long, help: "Test without building")
    var testWithoutBuilding: Bool = false
    
    @Flag(name: .long, help: "Collect screenshots on failure")
    var screenshots: Bool = false
    
    @Flag(name: .long, help: "Collect test attachments")
    var attachments: Bool = true
    
    @Flag(name: .long, help: "Use xcpretty for output formatting")
    var xcpretty: Bool = true
    
    @Flag(name: .long, help: "Fail if coverage is below minimum")
    var failOnCoverage: Bool = false
    
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
        
        logger.info("Running tests for \(platform.displayName)...")
        
        let result: TestResult
        
        switch platform {
        case .ios, .macos, .watchos, .tvos, .visionos:
            result = try await runXcodeTests()
        case .android:
            result = try await runAndroidTests()
        case .flutter:
            result = try await runFlutterTests()
        case .reactNative:
            result = try await runReactNativeTests()
        case .multiplatform:
            result = try await runMultiplatformTests()
        }
        
        // Report results
        let duration = Date().timeIntervalSince(startTime)
        try reportTestResult(result, duration: duration)
        
        // Exit with appropriate code
        if !result.success {
            throw TestError.testsFailed(
                total: result.totalTests,
                failed: result.failedTests
            )
        }
        
        // Check coverage
        if failOnCoverage, let minimumCoverage = minimumCoverage, let coverage = result.codeCoverage {
            if coverage.lineCoverage < minimumCoverage {
                throw TestError.coverageBelowMinimum(
                    actual: coverage.lineCoverage,
                    minimum: minimumCoverage
                )
            }
        }
    }
    
    // MARK: - Xcode Tests
    
    private func runXcodeTests() async throws -> TestResult {
        let logger = Logger.shared
        let startTime = Date()
        
        // Detect project
        let (projectArg, detectedScheme) = try detectXcodeProject()
        let testScheme = scheme ?? detectedScheme
        
        guard let testScheme = testScheme else {
            throw TestError.schemeNotFound
        }
        
        var args: [String] = []
        
        // Project/Workspace
        args.append(projectArg)
        args.append("-scheme \"\(testScheme)\"")
        
        // Destination
        if let destination = destination {
            args.append("-destination \"\(destination)\"")
        } else if let defaultDest = platform.defaultXcodeDestination {
            args.append("-destination \"\(defaultDest)\"")
        }
        
        // Test plan
        if let testPlan = testPlan {
            args.append("-testPlan \"\(testPlan)\"")
        }
        
        // Result bundle
        let resultBundle = resultBundlePath ?? "build/TestResults.xcresult"
        args.append("-resultBundlePath \"\(resultBundle)\"")
        
        // Code coverage
        if coverage {
            args.append("-enableCodeCoverage YES")
        }
        
        // Parallel testing
        if parallel {
            args.append("-parallel-testing-enabled YES")
            if let maxParallelism = maxParallelism {
                args.append("-parallel-testing-worker-count \(maxParallelism)")
            }
        }
        
        // Only/Skip tests
        for test in onlyTests {
            args.append("-only-testing:\(test)")
        }
        for test in skipTests {
            args.append("-skip-testing:\(test)")
        }
        
        // Retry count
        if let retryCount = retryCount {
            args.append("-retry-tests-on-failure")
            args.append("-test-iterations \(retryCount + 1)")
        }
        
        // Additional arguments
        args.append(contentsOf: testArgs)
        
        // Environment variables
        for envVar in env {
            let parts = envVar.split(separator: "=", maxSplits: 1)
            if parts.count == 2 {
                args.append("-\(parts[0]) \(parts[1])")
            }
        }
        
        // Determine action
        var action: String
        if buildForTesting {
            action = "build-for-testing"
        } else if testWithoutBuilding {
            action = "test-without-building"
        } else {
            action = "test"
        }
        
        var command = "xcodebuild \(action) \(args.joined(separator: " "))"
        
        if xcpretty && !verbose {
            command += " | xcpretty --report junit --output build/test-results.xml"
        }
        
        logger.debug("Test command: \(command)")
        
        if dryRun {
            logger.info("[DRY RUN] Would execute: \(command)")
            return TestResult(
                success: true,
                totalTests: 0,
                passedTests: 0,
                failedTests: 0,
                skippedTests: 0,
                duration: 0,
                testSuites: []
            )
        }
        
        let result = try ProcessRunner.shared.run(
            command,
            options: .default
                .with(printOutput: true)
                .with(timeout: timeout.map { TimeInterval($0) })
        )
        
        let endTime = Date()
        
        // Parse test results
        let testResult = try await parseXcodeResults(
            resultBundle: resultBundle,
            success: result.success,
            duration: endTime.timeIntervalSince(startTime)
        )
        
        return testResult
    }
    
    private func detectXcodeProject() throws -> (String, String?) {
        let fileManager = FileManager.default
        let currentDir = fileManager.currentDirectoryPath
        let contents = try fileManager.contentsOfDirectory(atPath: currentDir)
        
        // Check explicit values first
        if let workspace = workspace {
            return ("-workspace \"\(workspace)\"", nil)
        }
        if let project = project {
            return ("-project \"\(project)\"", nil)
        }
        if let package = package {
            return ("-package-path \"\(package)\"", nil)
        }
        
        // Auto-detect
        if let workspaceFile = contents.first(where: { $0.hasSuffix(".xcworkspace") }) {
            return ("-workspace \"\(workspaceFile)\"", try detectScheme(from: workspaceFile))
        }
        if let projectFile = contents.first(where: { $0.hasSuffix(".xcodeproj") }) {
            return ("-project \"\(projectFile)\"", try detectScheme(from: projectFile))
        }
        if contents.contains("Package.swift") {
            return ("-package-path .", nil)
        }
        
        throw TestError.projectNotFound
    }
    
    private func detectScheme(from projectOrWorkspace: String) throws -> String? {
        let isWorkspace = projectOrWorkspace.hasSuffix(".xcworkspace")
        let flag = isWorkspace ? "-workspace" : "-project"
        
        let result = try ProcessRunner.shared.run(
            "xcodebuild \(flag) \"\(projectOrWorkspace)\" -list -json"
        )
        
        guard result.success,
              let data = result.stdout.data(using: .utf8),
              let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let projectInfo = json["project"] as? [String: Any] ?? json["workspace"] as? [String: Any],
              let schemes = projectInfo["schemes"] as? [String] else {
            return nil
        }
        
        // Prefer test schemes
        if let testScheme = schemes.first(where: { $0.contains("Tests") || $0.contains("Test") }) {
            return testScheme
        }
        
        return schemes.first
    }
    
    private func parseXcodeResults(resultBundle: String, success: Bool, duration: TimeInterval) async throws -> TestResult {
        var totalTests = 0
        var passedTests = 0
        var failedTests = 0
        var skippedTests = 0
        var testSuites: [TestResult.TestSuite] = []
        var codeCoverage: TestResult.CodeCoverage?
        
        // Try to parse xcresult bundle
        let xcresultParser = XCResultParser()
        
        do {
            let parsedResult = try await xcresultParser.parse(resultBundle: resultBundle)
            totalTests = parsedResult.totalTests
            passedTests = parsedResult.passedTests
            failedTests = parsedResult.failedTests
            skippedTests = parsedResult.skippedTests
            testSuites = parsedResult.testSuites
            
            if coverage {
                codeCoverage = try await xcresultParser.parseCoverage(resultBundle: resultBundle)
            }
        } catch {
            Logger.shared.warning("Could not parse xcresult: \(error.localizedDescription)")
        }
        
        return TestResult(
            success: success && failedTests == 0,
            totalTests: totalTests,
            passedTests: passedTests,
            failedTests: failedTests,
            skippedTests: skippedTests,
            duration: duration,
            testSuites: testSuites,
            codeCoverage: codeCoverage,
            resultBundlePath: resultBundle
        )
    }
    
    // MARK: - Android Tests
    
    private func runAndroidTests() async throws -> TestResult {
        let logger = Logger.shared
        let startTime = Date()
        
        var gradleTask: String
        
        if unitOnly {
            gradleTask = "test"
        } else if uiOnly || integrationOnly {
            gradleTask = "connectedAndroidTest"
        } else {
            gradleTask = "test"
        }
        
        if let target = target {
            gradleTask = ":\(target):\(gradleTask)"
        }
        
        var args: [String] = [gradleTask]
        
        if coverage {
            args.append("jacocoTestReport")
        }
        
        if verbose {
            args.append("--info")
        }
        
        if let maxParallelism = maxParallelism {
            args.append("--max-workers=\(maxParallelism)")
        }
        
        // Filter tests
        if !onlyTests.isEmpty {
            let testFilter = onlyTests.joined(separator: ",")
            args.append("--tests \"\(testFilter)\"")
        }
        
        args.append(contentsOf: testArgs)
        
        let command = "./gradlew \(args.joined(separator: " "))"
        
        logger.debug("Test command: \(command)")
        
        if dryRun {
            logger.info("[DRY RUN] Would execute: \(command)")
            return TestResult(
                success: true,
                totalTests: 0,
                passedTests: 0,
                failedTests: 0,
                skippedTests: 0,
                duration: 0,
                testSuites: []
            )
        }
        
        let result = try ProcessRunner.shared.run(
            command,
            options: .default
                .with(printOutput: true)
                .with(timeout: timeout.map { TimeInterval($0) })
        )
        
        let endTime = Date()
        
        // Parse test results from XML
        let testResult = try parseAndroidResults(
            success: result.success,
            duration: endTime.timeIntervalSince(startTime)
        )
        
        return testResult
    }
    
    private func parseAndroidResults(success: Bool, duration: TimeInterval) throws -> TestResult {
        let testReportPath = "app/build/test-results"
        
        var totalTests = 0
        var passedTests = 0
        var failedTests = 0
        var skippedTests = 0
        var testSuites: [TestResult.TestSuite] = []
        
        let fileManager = FileManager.default
        
        if fileManager.fileExists(atPath: testReportPath) {
            let enumerator = fileManager.enumerator(atPath: testReportPath)
            
            while let file = enumerator?.nextObject() as? String {
                if file.hasSuffix(".xml") {
                    let xmlPath = (testReportPath as NSString).appendingPathComponent(file)
                    if let parsed = try? parseJUnitXML(at: xmlPath) {
                        testSuites.append(parsed)
                        for test in parsed.tests {
                            totalTests += 1
                            switch test.status {
                            case .passed: passedTests += 1
                            case .failed: failedTests += 1
                            case .skipped: skippedTests += 1
                            default: break
                            }
                        }
                    }
                }
            }
        }
        
        var codeCoverage: TestResult.CodeCoverage?
        
        if coverage {
            let coverageReportPath = "app/build/reports/jacoco"
            if fileManager.fileExists(atPath: coverageReportPath) {
                codeCoverage = try parseJacocoCoverage(at: coverageReportPath)
            }
        }
        
        return TestResult(
            success: success && failedTests == 0,
            totalTests: totalTests,
            passedTests: passedTests,
            failedTests: failedTests,
            skippedTests: skippedTests,
            duration: duration,
            testSuites: testSuites,
            codeCoverage: codeCoverage
        )
    }
    
    // MARK: - Flutter Tests
    
    private func runFlutterTests() async throws -> TestResult {
        let logger = Logger.shared
        let startTime = Date()
        
        var args: [String] = ["test"]
        
        if coverage {
            args.append("--coverage")
        }
        
        if verbose {
            args.append("--verbose")
        }
        
        // Reporter
        switch reporter {
        case .json:
            args.append("--machine")
        case .junit:
            args.append("--reporter json")
        default:
            break
        }
        
        // Concurrency
        if let maxParallelism = maxParallelism {
            args.append("--concurrency=\(maxParallelism)")
        }
        
        // Filter tests
        if !onlyTests.isEmpty {
            for test in onlyTests {
                args.append("--name \"\(test)\"")
            }
        }
        
        args.append(contentsOf: testArgs)
        
        let command = "flutter \(args.joined(separator: " "))"
        
        logger.debug("Test command: \(command)")
        
        if dryRun {
            logger.info("[DRY RUN] Would execute: \(command)")
            return TestResult(
                success: true,
                totalTests: 0,
                passedTests: 0,
                failedTests: 0,
                skippedTests: 0,
                duration: 0,
                testSuites: []
            )
        }
        
        var outputLines: [String] = []
        
        let result = try ProcessRunner.shared.runWithHandler(
            command,
            options: .default.with(timeout: timeout.map { TimeInterval($0) }),
            stdoutHandler: { line in
                print(line, terminator: "")
                outputLines.append(line)
            },
            stderrHandler: { line in
                FileHandle.standardError.write(line.data(using: .utf8) ?? Data())
            }
        )
        
        let endTime = Date()
        
        // Parse results
        let testResult = try parseFlutterResults(
            output: outputLines.joined(separator: "\n"),
            success: result.success,
            duration: endTime.timeIntervalSince(startTime)
        )
        
        return testResult
    }
    
    private func parseFlutterResults(output: String, success: Bool, duration: TimeInterval) throws -> TestResult {
        var totalTests = 0
        var passedTests = 0
        var failedTests = 0
        var skippedTests = 0
        
        // Parse Flutter test output
        let lines = output.components(separatedBy: .newlines)
        
        for line in lines {
            if line.contains("All tests passed!") {
                // Success indicator
            } else if let match = line.range(of: #"(\d+) tests? passed"#, options: .regularExpression) {
                let numStr = line[match].components(separatedBy: CharacterSet.decimalDigits.inverted).joined()
                passedTests = Int(numStr) ?? 0
            } else if let match = line.range(of: #"(\d+) tests? failed"#, options: .regularExpression) {
                let numStr = line[match].components(separatedBy: CharacterSet.decimalDigits.inverted).joined()
                failedTests = Int(numStr) ?? 0
            } else if let match = line.range(of: #"(\d+) tests? skipped"#, options: .regularExpression) {
                let numStr = line[match].components(separatedBy: CharacterSet.decimalDigits.inverted).joined()
                skippedTests = Int(numStr) ?? 0
            }
        }
        
        totalTests = passedTests + failedTests + skippedTests
        
        var codeCoverage: TestResult.CodeCoverage?
        
        if coverage {
            let coverageFile = "coverage/lcov.info"
            if FileManager.default.fileExists(atPath: coverageFile) {
                codeCoverage = try parseLcovCoverage(at: coverageFile)
            }
        }
        
        return TestResult(
            success: success && failedTests == 0,
            totalTests: totalTests,
            passedTests: passedTests,
            failedTests: failedTests,
            skippedTests: skippedTests,
            duration: duration,
            testSuites: [],
            codeCoverage: codeCoverage
        )
    }
    
    // MARK: - React Native Tests
    
    private func runReactNativeTests() async throws -> TestResult {
        let logger = Logger.shared
        let startTime = Date()
        
        var args: [String] = ["test"]
        
        if coverage {
            args.append("--coverage")
        }
        
        if verbose {
            args.append("--verbose")
        }
        
        // Reporter
        switch reporter {
        case .junit:
            args.append("--reporters=jest-junit")
        case .json:
            args.append("--json")
        default:
            break
        }
        
        // Concurrency
        if let maxParallelism = maxParallelism {
            args.append("--maxWorkers=\(maxParallelism)")
        }
        
        // Filter tests
        if !onlyTests.isEmpty {
            let testPattern = onlyTests.joined(separator: "|")
            args.append("--testNamePattern=\"\(testPattern)\"")
        }
        
        args.append(contentsOf: testArgs)
        
        // Detect package manager
        let useYarn = FileManager.default.fileExists(atPath: "yarn.lock")
        let command = useYarn ? "yarn \(args.joined(separator: " "))" : "npm \(args.joined(separator: " "))"
        
        logger.debug("Test command: \(command)")
        
        if dryRun {
            logger.info("[DRY RUN] Would execute: \(command)")
            return TestResult(
                success: true,
                totalTests: 0,
                passedTests: 0,
                failedTests: 0,
                skippedTests: 0,
                duration: 0,
                testSuites: []
            )
        }
        
        let result = try ProcessRunner.shared.run(
            command,
            options: .default
                .with(printOutput: true)
                .with(timeout: timeout.map { TimeInterval($0) })
        )
        
        let endTime = Date()
        
        // Parse results
        let testResult = try parseJestResults(
            output: result.stdout,
            success: result.success,
            duration: endTime.timeIntervalSince(startTime)
        )
        
        return testResult
    }
    
    private func parseJestResults(output: String, success: Bool, duration: TimeInterval) throws -> TestResult {
        var totalTests = 0
        var passedTests = 0
        var failedTests = 0
        var skippedTests = 0
        
        // Parse Jest output
        let lines = output.components(separatedBy: .newlines)
        
        for line in lines {
            // Look for summary line like "Tests:       2 passed, 2 total"
            if line.contains("Tests:") {
                if let match = line.range(of: #"(\d+) passed"#, options: .regularExpression) {
                    let numStr = line[match].components(separatedBy: CharacterSet.decimalDigits.inverted).joined()
                    passedTests = Int(numStr) ?? 0
                }
                if let match = line.range(of: #"(\d+) failed"#, options: .regularExpression) {
                    let numStr = line[match].components(separatedBy: CharacterSet.decimalDigits.inverted).joined()
                    failedTests = Int(numStr) ?? 0
                }
                if let match = line.range(of: #"(\d+) skipped"#, options: .regularExpression) {
                    let numStr = line[match].components(separatedBy: CharacterSet.decimalDigits.inverted).joined()
                    skippedTests = Int(numStr) ?? 0
                }
                if let match = line.range(of: #"(\d+) total"#, options: .regularExpression) {
                    let numStr = line[match].components(separatedBy: CharacterSet.decimalDigits.inverted).joined()
                    totalTests = Int(numStr) ?? 0
                }
            }
        }
        
        var codeCoverage: TestResult.CodeCoverage?
        
        if coverage {
            let coverageFile = "coverage/lcov.info"
            if FileManager.default.fileExists(atPath: coverageFile) {
                codeCoverage = try parseLcovCoverage(at: coverageFile)
            }
        }
        
        return TestResult(
            success: success && failedTests == 0,
            totalTests: totalTests,
            passedTests: passedTests,
            failedTests: failedTests,
            skippedTests: skippedTests,
            duration: duration,
            testSuites: [],
            codeCoverage: codeCoverage
        )
    }
    
    // MARK: - Multiplatform Tests
    
    private func runMultiplatformTests() async throws -> TestResult {
        let logger = Logger.shared
        let startTime = Date()
        
        logger.info("Running tests for multiple platforms...")
        
        var totalTests = 0
        var passedTests = 0
        var failedTests = 0
        var skippedTests = 0
        var allTestSuites: [TestResult.TestSuite] = []
        
        // Detect platforms
        var platformsToTest: [Platform] = []
        
        let fileManager = FileManager.default
        
        if fileManager.fileExists(atPath: "ios") || fileManager.fileExists(atPath: "Package.swift") {
            platformsToTest.append(.ios)
        }
        if fileManager.fileExists(atPath: "android") {
            platformsToTest.append(.android)
        }
        if fileManager.fileExists(atPath: "pubspec.yaml") {
            platformsToTest.append(.flutter)
        }
        
        for targetPlatform in platformsToTest {
            logger.info("Testing \(targetPlatform.displayName)...")
            
            var modifiedCommand = self
            modifiedCommand.platform = targetPlatform
            
            let result: TestResult
            
            switch targetPlatform {
            case .ios:
                result = try await modifiedCommand.runXcodeTests()
            case .android:
                result = try await modifiedCommand.runAndroidTests()
            case .flutter:
                result = try await modifiedCommand.runFlutterTests()
            default:
                continue
            }
            
            totalTests += result.totalTests
            passedTests += result.passedTests
            failedTests += result.failedTests
            skippedTests += result.skippedTests
            allTestSuites.append(contentsOf: result.testSuites)
        }
        
        let endTime = Date()
        
        return TestResult(
            success: failedTests == 0,
            totalTests: totalTests,
            passedTests: passedTests,
            failedTests: failedTests,
            skippedTests: skippedTests,
            duration: endTime.timeIntervalSince(startTime),
            testSuites: allTestSuites
        )
    }
    
    // MARK: - Parsing Helpers
    
    private func parseJUnitXML(at path: String) throws -> TestResult.TestSuite {
        // Basic JUnit XML parsing
        let data = try Data(contentsOf: URL(fileURLWithPath: path))
        
        guard let xml = String(data: data, encoding: .utf8) else {
            throw TestError.parseError("Invalid XML encoding")
        }
        
        var tests: [TestResult.TestCase] = []
        var suiteName = "Unknown"
        var suiteDuration: TimeInterval = 0
        
        // Very basic XML parsing (in production, use XMLParser)
        if let nameMatch = xml.range(of: #"name="([^"]+)""#, options: .regularExpression) {
            suiteName = String(xml[nameMatch]).replacingOccurrences(of: "name=\"", with: "").replacingOccurrences(of: "\"", with: "")
        }
        
        if let timeMatch = xml.range(of: #"time="([^"]+)""#, options: .regularExpression) {
            let timeStr = String(xml[timeMatch]).replacingOccurrences(of: "time=\"", with: "").replacingOccurrences(of: "\"", with: "")
            suiteDuration = Double(timeStr) ?? 0
        }
        
        return TestResult.TestSuite(
            name: suiteName,
            tests: tests,
            duration: suiteDuration
        )
    }
    
    private func parseJacocoCoverage(at path: String) throws -> TestResult.CodeCoverage {
        // Basic Jacoco coverage parsing
        return TestResult.CodeCoverage(
            lineCoverage: 0,
            branchCoverage: nil,
            functionCoverage: nil,
            files: []
        )
    }
    
    private func parseLcovCoverage(at path: String) throws -> TestResult.CodeCoverage {
        let content = try String(contentsOfFile: path, encoding: .utf8)
        let lines = content.components(separatedBy: .newlines)
        
        var totalLines = 0
        var coveredLines = 0
        var files: [TestResult.CodeCoverage.FileCoverage] = []
        var currentFile: String?
        var currentCovered = 0
        var currentTotal = 0
        
        for line in lines {
            if line.hasPrefix("SF:") {
                if let file = currentFile, currentTotal > 0 {
                    files.append(TestResult.CodeCoverage.FileCoverage(
                        path: file,
                        lineCoverage: Double(currentCovered) / Double(currentTotal) * 100,
                        coveredLines: currentCovered,
                        executableLines: currentTotal
                    ))
                }
                currentFile = String(line.dropFirst(3))
                currentCovered = 0
                currentTotal = 0
            } else if line.hasPrefix("DA:") {
                let parts = line.dropFirst(3).split(separator: ",")
                if parts.count >= 2 {
                    currentTotal += 1
                    totalLines += 1
                    if let hits = Int(parts[1]), hits > 0 {
                        currentCovered += 1
                        coveredLines += 1
                    }
                }
            }
        }
        
        if let file = currentFile, currentTotal > 0 {
            files.append(TestResult.CodeCoverage.FileCoverage(
                path: file,
                lineCoverage: Double(currentCovered) / Double(currentTotal) * 100,
                coveredLines: currentCovered,
                executableLines: currentTotal
            ))
        }
        
        let lineCoverage = totalLines > 0 ? Double(coveredLines) / Double(totalLines) * 100 : 0
        
        return TestResult.CodeCoverage(
            lineCoverage: lineCoverage,
            branchCoverage: nil,
            functionCoverage: nil,
            files: files
        )
    }
    
    // MARK: - Reporting
    
    private func reportTestResult(_ result: TestResult, duration: TimeInterval) throws {
        let logger = Logger.shared
        
        let formatter = DateComponentsFormatter()
        formatter.allowedUnits = [.minute, .second]
        formatter.unitsStyle = .abbreviated
        let durationString = formatter.string(from: duration) ?? "\(Int(duration))s"
        
        // Summary table
        let table = TableFormatter(columns: [
            TableFormatter.Column(header: "Metric", width: 15),
            TableFormatter.Column(header: "Value", width: 10, alignment: .right)
        ])
        
        let rows = [
            ["Total Tests", "\(result.totalTests)"],
            ["Passed", "\(result.passedTests)"],
            ["Failed", "\(result.failedTests)"],
            ["Skipped", "\(result.skippedTests)"],
            ["Duration", durationString]
        ]
        
        print()
        print(table.format(rows: rows))
        print()
        
        if result.success {
            logger.success("All tests passed! (\(result.passedTests)/\(result.totalTests))")
        } else {
            logger.error("Tests failed: \(result.failedTests) of \(result.totalTests)")
            
            // Print failed test details
            for suite in result.testSuites {
                for test in suite.tests where test.status == .failed {
                    logger.error("  ✗ \(suite.name)/\(test.name)")
                    if let message = test.failureMessage {
                        logger.error("    \(message)")
                    }
                }
            }
        }
        
        // Print coverage
        if let coverage = result.codeCoverage {
            print()
            logger.info("Code Coverage: \(String(format: "%.1f%%", coverage.lineCoverage))")
            
            if verbose {
                let coverageTable = TableFormatter(columns: [
                    TableFormatter.Column(header: "File", width: 50),
                    TableFormatter.Column(header: "Coverage", width: 10, alignment: .right)
                ])
                
                let coverageRows = coverage.files.prefix(20).map { file -> [String] in
                    let fileName = URL(fileURLWithPath: file.path).lastPathComponent
                    return [fileName, String(format: "%.1f%%", file.lineCoverage)]
                }
                
                print(coverageTable.format(rows: Array(coverageRows)))
            }
            
            if let minimum = minimumCoverage {
                if coverage.lineCoverage >= minimum {
                    logger.success("Coverage meets minimum requirement (\(String(format: "%.1f%%", minimum)))")
                } else {
                    logger.warning("Coverage below minimum requirement (\(String(format: "%.1f%%", minimum)))")
                }
            }
        }
        
        // Export results
        if let output = output {
            try exportResults(result, to: output)
        }
    }
    
    private func exportResults(_ result: TestResult, to path: String) throws {
        let fileManager = FileManager.default
        try fileManager.createDirectory(atPath: path, withIntermediateDirectories: true)
        
        // Export JSON summary
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        let jsonData = try encoder.encode(result)
        let jsonPath = (path as NSString).appendingPathComponent("test-results.json")
        try jsonData.write(to: URL(fileURLWithPath: jsonPath))
        
        Logger.shared.info("Results exported to: \(path)")
    }
}

// MARK: - Test Reporter

/// Test reporter format options
public enum TestReporter: String, ExpressibleByArgument, CaseIterable {
    case xcresult
    case junit
    case html
    case json
    case markdown
    
    public static var allValueStrings: [String] {
        return allCases.map { $0.rawValue }
    }
}

// MARK: - XCResult Parser

/// Parser for Xcode result bundles
public final class XCResultParser {
    public struct ParsedResult {
        public let totalTests: Int
        public let passedTests: Int
        public let failedTests: Int
        public let skippedTests: Int
        public let testSuites: [TestResult.TestSuite]
    }
    
    public func parse(resultBundle: String) async throws -> ParsedResult {
        // Use xcresulttool to parse the bundle
        let result = try ProcessRunner.shared.run(
            "xcrun xcresulttool get --format json --path \"\(resultBundle)\""
        )
        
        guard result.success else {
            throw TestError.parseError("Failed to parse xcresult: \(result.stderr)")
        }
        
        // Parse JSON output
        guard let data = result.stdout.data(using: .utf8),
              let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else {
            throw TestError.parseError("Invalid xcresult JSON")
        }
        
        var totalTests = 0
        var passedTests = 0
        var failedTests = 0
        var skippedTests = 0
        
        // Extract test counts from JSON structure
        if let actions = json["actions"] as? [String: Any],
           let values = actions["_values"] as? [[String: Any]] {
            for action in values {
                if let testRef = action["testsRef"] as? [String: Any],
                   let id = testRef["id"] as? [String: Any],
                   let idValue = id["_value"] as? String {
                    // Fetch test details
                    let detailResult = try? ProcessRunner.shared.run(
                        "xcrun xcresulttool get --format json --path \"\(resultBundle)\" --id \(idValue)"
                    )
                    
                    if let detailOutput = detailResult?.stdout,
                       let detailData = detailOutput.data(using: .utf8),
                       let detailJson = try? JSONSerialization.jsonObject(with: detailData) as? [String: Any] {
                        // Count tests from detail JSON
                        countTests(from: detailJson, total: &totalTests, passed: &passedTests, failed: &failedTests, skipped: &skippedTests)
                    }
                }
            }
        }
        
        return ParsedResult(
            totalTests: totalTests,
            passedTests: passedTests,
            failedTests: failedTests,
            skippedTests: skippedTests,
            testSuites: []
        )
    }
    
    private func countTests(from json: [String: Any], total: inout Int, passed: inout Int, failed: inout Int, skipped: inout Int) {
        // Recursive function to count tests
        if let subtests = json["subtests"] as? [String: Any],
           let values = subtests["_values"] as? [[String: Any]] {
            for subtest in values {
                if let testStatus = subtest["testStatus"] as? [String: Any],
                   let status = testStatus["_value"] as? String {
                    total += 1
                    switch status {
                    case "Success": passed += 1
                    case "Failure": failed += 1
                    case "Skipped": skipped += 1
                    default: break
                    }
                }
                countTests(from: subtest, total: &total, passed: &passed, failed: &failed, skipped: &skipped)
            }
        }
    }
    
    public func parseCoverage(resultBundle: String) async throws -> TestResult.CodeCoverage {
        let result = try ProcessRunner.shared.run(
            "xcrun xccov view --report --json \"\(resultBundle)\""
        )
        
        guard result.success else {
            throw TestError.parseError("Failed to parse coverage: \(result.stderr)")
        }
        
        guard let data = result.stdout.data(using: .utf8),
              let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else {
            throw TestError.parseError("Invalid coverage JSON")
        }
        
        var lineCoverage: Double = 0
        var files: [TestResult.CodeCoverage.FileCoverage] = []
        
        if let coverage = json["lineCoverage"] as? Double {
            lineCoverage = coverage * 100
        }
        
        if let targets = json["targets"] as? [[String: Any]] {
            for target in targets {
                if let targetFiles = target["files"] as? [[String: Any]] {
                    for file in targetFiles {
                        if let path = file["path"] as? String,
                           let fileCoverage = file["lineCoverage"] as? Double,
                           let covered = file["coveredLines"] as? Int,
                           let executable = file["executableLines"] as? Int {
                            files.append(TestResult.CodeCoverage.FileCoverage(
                                path: path,
                                lineCoverage: fileCoverage * 100,
                                coveredLines: covered,
                                executableLines: executable
                            ))
                        }
                    }
                }
            }
        }
        
        return TestResult.CodeCoverage(
            lineCoverage: lineCoverage,
            branchCoverage: nil,
            functionCoverage: nil,
            files: files
        )
    }
}

// MARK: - Test Errors

/// Errors that can occur during testing
public enum TestError: LocalizedError {
    case projectNotFound
    case schemeNotFound
    case testsFailed(total: Int, failed: Int)
    case coverageBelowMinimum(actual: Double, minimum: Double)
    case parseError(String)
    case timeout
    
    public var errorDescription: String? {
        switch self {
        case .projectNotFound:
            return "No Xcode project or workspace found in the current directory"
        case .schemeNotFound:
            return "No test scheme found. Specify one with --scheme"
        case .testsFailed(let total, let failed):
            return "\(failed) of \(total) tests failed"
        case .coverageBelowMinimum(let actual, let minimum):
            return String(format: "Code coverage (%.1f%%) is below minimum (%.1f%%)", actual, minimum)
        case .parseError(let message):
            return "Failed to parse test results: \(message)"
        case .timeout:
            return "Tests timed out"
        }
    }
}
