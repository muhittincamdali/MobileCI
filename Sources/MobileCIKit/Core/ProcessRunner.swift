// ProcessRunner.swift
// MobileCIKit
//
// Process execution and management for shell commands.

import Foundation

// MARK: - Process Result

/// Result of a process execution
public struct ProcessResult: Sendable {
    public let exitCode: Int32
    public let stdout: String
    public let stderr: String
    public let duration: TimeInterval
    public let command: String
    
    public var success: Bool {
        return exitCode == 0
    }
    
    public var combinedOutput: String {
        if stderr.isEmpty {
            return stdout
        } else if stdout.isEmpty {
            return stderr
        } else {
            return stdout + "\n" + stderr
        }
    }
    
    public init(
        exitCode: Int32,
        stdout: String,
        stderr: String,
        duration: TimeInterval,
        command: String
    ) {
        self.exitCode = exitCode
        self.stdout = stdout
        self.stderr = stderr
        self.duration = duration
        self.command = command
    }
}

// MARK: - Process Options

/// Options for process execution
public struct ProcessOptions: Sendable {
    public let workingDirectory: String?
    public let environment: [String: String]
    public let inheritEnvironment: Bool
    public let timeout: TimeInterval?
    public let captureOutput: Bool
    public let printOutput: Bool
    public let shell: String
    public let shellArgs: [String]
    
    public static let `default` = ProcessOptions()
    
    public init(
        workingDirectory: String? = nil,
        environment: [String: String] = [:],
        inheritEnvironment: Bool = true,
        timeout: TimeInterval? = nil,
        captureOutput: Bool = true,
        printOutput: Bool = false,
        shell: String = "/bin/bash",
        shellArgs: [String] = ["-c"]
    ) {
        self.workingDirectory = workingDirectory
        self.environment = environment
        self.inheritEnvironment = inheritEnvironment
        self.timeout = timeout
        self.captureOutput = captureOutput
        self.printOutput = printOutput
        self.shell = shell
        self.shellArgs = shellArgs
    }
    
    public func with(workingDirectory: String?) -> ProcessOptions {
        return ProcessOptions(
            workingDirectory: workingDirectory,
            environment: environment,
            inheritEnvironment: inheritEnvironment,
            timeout: timeout,
            captureOutput: captureOutput,
            printOutput: printOutput,
            shell: shell,
            shellArgs: shellArgs
        )
    }
    
    public func with(environment: [String: String]) -> ProcessOptions {
        var merged = self.environment
        for (key, value) in environment {
            merged[key] = value
        }
        return ProcessOptions(
            workingDirectory: workingDirectory,
            environment: merged,
            inheritEnvironment: inheritEnvironment,
            timeout: timeout,
            captureOutput: captureOutput,
            printOutput: printOutput,
            shell: shell,
            shellArgs: shellArgs
        )
    }
    
    public func with(timeout: TimeInterval?) -> ProcessOptions {
        return ProcessOptions(
            workingDirectory: workingDirectory,
            environment: environment,
            inheritEnvironment: inheritEnvironment,
            timeout: timeout,
            captureOutput: captureOutput,
            printOutput: printOutput,
            shell: shell,
            shellArgs: shellArgs
        )
    }
    
    public func with(printOutput: Bool) -> ProcessOptions {
        return ProcessOptions(
            workingDirectory: workingDirectory,
            environment: environment,
            inheritEnvironment: inheritEnvironment,
            timeout: timeout,
            captureOutput: captureOutput,
            printOutput: printOutput,
            shell: shell,
            shellArgs: shellArgs
        )
    }
}

// MARK: - Process Runner

/// Runs shell commands and processes
public final class ProcessRunner: @unchecked Sendable {
    public static let shared = ProcessRunner()
    
    private let queue = DispatchQueue(label: "com.mobileci.processrunner", attributes: .concurrent)
    private var runningProcesses: [UUID: Process] = [:]
    private let lock = NSLock()
    
    private init() {}
    
    // MARK: - Synchronous Execution
    
    /// Run a command synchronously
    @discardableResult
    public func run(_ command: String, options: ProcessOptions = .default) throws -> ProcessResult {
        let startTime = Date()
        
        let process = Process()
        process.executableURL = URL(fileURLWithPath: options.shell)
        process.arguments = options.shellArgs + [command]
        
        // Set working directory
        if let workingDirectory = options.workingDirectory {
            process.currentDirectoryURL = URL(fileURLWithPath: workingDirectory)
        }
        
        // Set environment
        var env: [String: String] = [:]
        if options.inheritEnvironment {
            env = ProcessInfo.processInfo.environment
        }
        for (key, value) in options.environment {
            env[key] = value
        }
        process.environment = env
        
        // Setup pipes
        let stdoutPipe = Pipe()
        let stderrPipe = Pipe()
        
        if options.captureOutput {
            process.standardOutput = stdoutPipe
            process.standardError = stderrPipe
        }
        
        var stdoutData = Data()
        var stderrData = Data()
        
        if options.printOutput && options.captureOutput {
            stdoutPipe.fileHandleForReading.readabilityHandler = { handle in
                let data = handle.availableData
                if !data.isEmpty {
                    stdoutData.append(data)
                    if let str = String(data: data, encoding: .utf8) {
                        print(str, terminator: "")
                    }
                }
            }
            
            stderrPipe.fileHandleForReading.readabilityHandler = { handle in
                let data = handle.availableData
                if !data.isEmpty {
                    stderrData.append(data)
                    if let str = String(data: data, encoding: .utf8) {
                        FileHandle.standardError.write(data)
                    }
                }
            }
        }
        
        let processId = UUID()
        registerProcess(process, id: processId)
        defer { unregisterProcess(id: processId) }
        
        // Handle timeout
        var timeoutWorkItem: DispatchWorkItem?
        if let timeout = options.timeout {
            timeoutWorkItem = DispatchWorkItem { [weak process] in
                process?.terminate()
            }
            DispatchQueue.global().asyncAfter(deadline: .now() + timeout, execute: timeoutWorkItem!)
        }
        
        do {
            try process.run()
            process.waitUntilExit()
        } catch {
            timeoutWorkItem?.cancel()
            throw ProcessRunnerError.executionFailed(command: command, underlying: error)
        }
        
        timeoutWorkItem?.cancel()
        
        // Read remaining data
        if options.captureOutput && !options.printOutput {
            stdoutData = stdoutPipe.fileHandleForReading.readDataToEndOfFile()
            stderrData = stderrPipe.fileHandleForReading.readDataToEndOfFile()
        } else if options.captureOutput {
            stdoutPipe.fileHandleForReading.readabilityHandler = nil
            stderrPipe.fileHandleForReading.readabilityHandler = nil
        }
        
        let stdout = String(data: stdoutData, encoding: .utf8)?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        let stderr = String(data: stderrData, encoding: .utf8)?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        
        let duration = Date().timeIntervalSince(startTime)
        
        return ProcessResult(
            exitCode: process.terminationStatus,
            stdout: stdout,
            stderr: stderr,
            duration: duration,
            command: command
        )
    }
    
    // MARK: - Async Execution
    
    /// Run a command asynchronously
    public func runAsync(_ command: String, options: ProcessOptions = .default) async throws -> ProcessResult {
        return try await withCheckedThrowingContinuation { continuation in
            queue.async {
                do {
                    let result = try self.run(command, options: options)
                    continuation.resume(returning: result)
                } catch {
                    continuation.resume(throwing: error)
                }
            }
        }
    }
    
    /// Run a command asynchronously and require success
    public func runAsyncOrThrow(_ command: String, options: ProcessOptions = .default) async throws -> ProcessResult {
        let result = try await runAsync(command, options: options)
        guard result.success else {
            throw ProcessRunnerError.nonZeroExit(
                command: command,
                exitCode: result.exitCode,
                stderr: result.stderr
            )
        }
        return result
    }
    
    // MARK: - Convenience Methods
    
    /// Check if a command exists
    public func commandExists(_ command: String) -> Bool {
        let result = try? run("which \(command)")
        return result?.success == true
    }
    
    /// Get command output as string
    public func output(_ command: String, options: ProcessOptions = .default) throws -> String {
        let result = try run(command, options: options)
        guard result.success else {
            throw ProcessRunnerError.nonZeroExit(
                command: command,
                exitCode: result.exitCode,
                stderr: result.stderr
            )
        }
        return result.stdout
    }
    
    /// Run multiple commands sequentially
    public func runSequence(_ commands: [String], options: ProcessOptions = .default) throws -> [ProcessResult] {
        var results: [ProcessResult] = []
        
        for command in commands {
            let result = try run(command, options: options)
            results.append(result)
            
            guard result.success else {
                throw ProcessRunnerError.sequenceFailed(
                    command: command,
                    index: results.count - 1,
                    result: result
                )
            }
        }
        
        return results
    }
    
    /// Run multiple commands in parallel
    public func runParallel(_ commands: [String], options: ProcessOptions = .default) async throws -> [ProcessResult] {
        return try await withThrowingTaskGroup(of: (Int, ProcessResult).self) { group in
            for (index, command) in commands.enumerated() {
                group.addTask {
                    let result = try await self.runAsync(command, options: options)
                    return (index, result)
                }
            }
            
            var results: [(Int, ProcessResult)] = []
            for try await result in group {
                results.append(result)
            }
            
            return results.sorted { $0.0 < $1.0 }.map { $0.1 }
        }
    }
    
    // MARK: - Streaming Output
    
    /// Run a command with streaming output handler
    public func runWithHandler(
        _ command: String,
        options: ProcessOptions = .default,
        stdoutHandler: @escaping (String) -> Void,
        stderrHandler: @escaping (String) -> Void
    ) throws -> ProcessResult {
        let startTime = Date()
        
        let process = Process()
        process.executableURL = URL(fileURLWithPath: options.shell)
        process.arguments = options.shellArgs + [command]
        
        if let workingDirectory = options.workingDirectory {
            process.currentDirectoryURL = URL(fileURLWithPath: workingDirectory)
        }
        
        var env: [String: String] = [:]
        if options.inheritEnvironment {
            env = ProcessInfo.processInfo.environment
        }
        for (key, value) in options.environment {
            env[key] = value
        }
        process.environment = env
        
        let stdoutPipe = Pipe()
        let stderrPipe = Pipe()
        
        process.standardOutput = stdoutPipe
        process.standardError = stderrPipe
        
        var allStdout = ""
        var allStderr = ""
        
        stdoutPipe.fileHandleForReading.readabilityHandler = { handle in
            let data = handle.availableData
            if let str = String(data: data, encoding: .utf8), !str.isEmpty {
                allStdout += str
                stdoutHandler(str)
            }
        }
        
        stderrPipe.fileHandleForReading.readabilityHandler = { handle in
            let data = handle.availableData
            if let str = String(data: data, encoding: .utf8), !str.isEmpty {
                allStderr += str
                stderrHandler(str)
            }
        }
        
        let processId = UUID()
        registerProcess(process, id: processId)
        defer { unregisterProcess(id: processId) }
        
        try process.run()
        process.waitUntilExit()
        
        stdoutPipe.fileHandleForReading.readabilityHandler = nil
        stderrPipe.fileHandleForReading.readabilityHandler = nil
        
        let duration = Date().timeIntervalSince(startTime)
        
        return ProcessResult(
            exitCode: process.terminationStatus,
            stdout: allStdout.trimmingCharacters(in: .whitespacesAndNewlines),
            stderr: allStderr.trimmingCharacters(in: .whitespacesAndNewlines),
            duration: duration,
            command: command
        )
    }
    
    // MARK: - Interactive Process
    
    /// Run an interactive process with stdin support
    public func runInteractive(_ command: String, input: String?, options: ProcessOptions = .default) throws -> ProcessResult {
        let startTime = Date()
        
        let process = Process()
        process.executableURL = URL(fileURLWithPath: options.shell)
        process.arguments = options.shellArgs + [command]
        
        if let workingDirectory = options.workingDirectory {
            process.currentDirectoryURL = URL(fileURLWithPath: workingDirectory)
        }
        
        var env: [String: String] = [:]
        if options.inheritEnvironment {
            env = ProcessInfo.processInfo.environment
        }
        for (key, value) in options.environment {
            env[key] = value
        }
        process.environment = env
        
        let stdinPipe = Pipe()
        let stdoutPipe = Pipe()
        let stderrPipe = Pipe()
        
        process.standardInput = stdinPipe
        process.standardOutput = stdoutPipe
        process.standardError = stderrPipe
        
        let processId = UUID()
        registerProcess(process, id: processId)
        defer { unregisterProcess(id: processId) }
        
        try process.run()
        
        if let input = input, let data = input.data(using: .utf8) {
            stdinPipe.fileHandleForWriting.write(data)
            stdinPipe.fileHandleForWriting.closeFile()
        }
        
        process.waitUntilExit()
        
        let stdoutData = stdoutPipe.fileHandleForReading.readDataToEndOfFile()
        let stderrData = stderrPipe.fileHandleForReading.readDataToEndOfFile()
        
        let stdout = String(data: stdoutData, encoding: .utf8)?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        let stderr = String(data: stderrData, encoding: .utf8)?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        
        let duration = Date().timeIntervalSince(startTime)
        
        return ProcessResult(
            exitCode: process.terminationStatus,
            stdout: stdout,
            stderr: stderr,
            duration: duration,
            command: command
        )
    }
    
    // MARK: - Process Management
    
    private func registerProcess(_ process: Process, id: UUID) {
        lock.lock()
        defer { lock.unlock() }
        runningProcesses[id] = process
    }
    
    private func unregisterProcess(id: UUID) {
        lock.lock()
        defer { lock.unlock() }
        runningProcesses.removeValue(forKey: id)
    }
    
    /// Terminate all running processes
    public func terminateAll() {
        lock.lock()
        let processes = Array(runningProcesses.values)
        lock.unlock()
        
        for process in processes {
            if process.isRunning {
                process.terminate()
            }
        }
    }
    
    /// Get count of running processes
    public var runningProcessCount: Int {
        lock.lock()
        defer { lock.unlock() }
        return runningProcesses.count
    }
}

// MARK: - Process Runner Errors

/// Errors that can occur during process execution
public enum ProcessRunnerError: LocalizedError {
    case executionFailed(command: String, underlying: Error)
    case nonZeroExit(command: String, exitCode: Int32, stderr: String)
    case timeout(command: String, timeout: TimeInterval)
    case sequenceFailed(command: String, index: Int, result: ProcessResult)
    case commandNotFound(command: String)
    
    public var errorDescription: String? {
        switch self {
        case .executionFailed(let command, let error):
            return "Failed to execute '\(command)': \(error.localizedDescription)"
        case .nonZeroExit(let command, let code, let stderr):
            return "Command '\(command)' exited with code \(code): \(stderr)"
        case .timeout(let command, let timeout):
            return "Command '\(command)' timed out after \(timeout) seconds"
        case .sequenceFailed(let command, let index, let result):
            return "Sequence failed at command \(index + 1) '\(command)': \(result.stderr)"
        case .commandNotFound(let command):
            return "Command '\(command)' not found"
        }
    }
}

// MARK: - Shell Builder

/// Builder for constructing complex shell commands
public final class ShellCommandBuilder {
    private var parts: [String] = []
    private var environment: [String: String] = [:]
    private var redirections: [String] = []
    
    public init() {}
    
    @discardableResult
    public func add(_ command: String) -> ShellCommandBuilder {
        parts.append(command)
        return self
    }
    
    @discardableResult
    public func pipe(_ command: String) -> ShellCommandBuilder {
        parts.append("| \(command)")
        return self
    }
    
    @discardableResult
    public func and(_ command: String) -> ShellCommandBuilder {
        parts.append("&& \(command)")
        return self
    }
    
    @discardableResult
    public func or(_ command: String) -> ShellCommandBuilder {
        parts.append("|| \(command)")
        return self
    }
    
    @discardableResult
    public func env(_ key: String, _ value: String) -> ShellCommandBuilder {
        environment[key] = value
        return self
    }
    
    @discardableResult
    public func redirectStdout(to path: String, append: Bool = false) -> ShellCommandBuilder {
        redirections.append(append ? ">> \(path)" : "> \(path)")
        return self
    }
    
    @discardableResult
    public func redirectStderr(to path: String, append: Bool = false) -> ShellCommandBuilder {
        redirections.append(append ? "2>> \(path)" : "2> \(path)")
        return self
    }
    
    @discardableResult
    public func redirectAll(to path: String, append: Bool = false) -> ShellCommandBuilder {
        redirections.append(append ? "&>> \(path)" : "&> \(path)")
        return self
    }
    
    @discardableResult
    public func background() -> ShellCommandBuilder {
        parts.append("&")
        return self
    }
    
    public func build() -> String {
        var envPrefix = ""
        if !environment.isEmpty {
            envPrefix = environment.map { "\($0.key)=\(escapeForShell($0.value))" }.joined(separator: " ") + " "
        }
        
        var command = envPrefix + parts.joined(separator: " ")
        
        if !redirections.isEmpty {
            command += " " + redirections.joined(separator: " ")
        }
        
        return command
    }
    
    private func escapeForShell(_ value: String) -> String {
        if value.contains(" ") || value.contains("\"") || value.contains("'") {
            return "'\(value.replacingOccurrences(of: "'", with: "'\\''"))'"
        }
        return value
    }
}

// MARK: - Convenience Extensions

extension ProcessRunner {
    /// Execute xcodebuild command
    public func xcodebuild(_ arguments: [String], options: ProcessOptions = .default) throws -> ProcessResult {
        let command = "xcodebuild " + arguments.joined(separator: " ")
        return try run(command, options: options)
    }
    
    /// Execute gradle command
    public func gradle(_ task: String, arguments: [String] = [], options: ProcessOptions = .default) throws -> ProcessResult {
        let args = [task] + arguments
        let command = "./gradlew " + args.joined(separator: " ")
        return try run(command, options: options)
    }
    
    /// Execute flutter command
    public func flutter(_ subcommand: String, arguments: [String] = [], options: ProcessOptions = .default) throws -> ProcessResult {
        let args = [subcommand] + arguments
        let command = "flutter " + args.joined(separator: " ")
        return try run(command, options: options)
    }
    
    /// Execute npm command
    public func npm(_ subcommand: String, arguments: [String] = [], options: ProcessOptions = .default) throws -> ProcessResult {
        let args = [subcommand] + arguments
        let command = "npm " + args.joined(separator: " ")
        return try run(command, options: options)
    }
    
    /// Execute fastlane command
    public func fastlane(_ lane: String, arguments: [String] = [], options: ProcessOptions = .default) throws -> ProcessResult {
        let args = [lane] + arguments
        let command = "fastlane " + args.joined(separator: " ")
        return try run(command, options: options)
    }
    
    /// Execute git command
    public func git(_ subcommand: String, arguments: [String] = [], options: ProcessOptions = .default) throws -> ProcessResult {
        let args = [subcommand] + arguments
        let command = "git " + args.joined(separator: " ")
        return try run(command, options: options)
    }
}
