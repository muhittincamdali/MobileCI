// Logger.swift
// MobileCIKit
//
// Comprehensive logging system for MobileCI operations.

import Foundation
import Rainbow

// MARK: - Log Level

/// Log levels for controlling output verbosity
public enum LogLevel: Int, Comparable, CaseIterable, Sendable {
    case trace = 0
    case debug = 1
    case info = 2
    case success = 3
    case warning = 4
    case error = 5
    case fatal = 6
    case silent = 7
    
    public static func < (lhs: LogLevel, rhs: LogLevel) -> Bool {
        return lhs.rawValue < rhs.rawValue
    }
    
    public var prefix: String {
        switch self {
        case .trace: return "TRACE"
        case .debug: return "DEBUG"
        case .info: return "INFO"
        case .success: return "SUCCESS"
        case .warning: return "WARNING"
        case .error: return "ERROR"
        case .fatal: return "FATAL"
        case .silent: return ""
        }
    }
    
    public var emoji: String {
        switch self {
        case .trace: return "🔍"
        case .debug: return "🐛"
        case .info: return "ℹ️"
        case .success: return "✅"
        case .warning: return "⚠️"
        case .error: return "❌"
        case .fatal: return "💀"
        case .silent: return ""
        }
    }
    
    public var color: String {
        switch self {
        case .trace: return "gray"
        case .debug: return "cyan"
        case .info: return "blue"
        case .success: return "green"
        case .warning: return "yellow"
        case .error: return "red"
        case .fatal: return "red"
        case .silent: return "default"
        }
    }
}

// MARK: - Log Destination

/// Destination for log output
public enum LogDestination: Sendable {
    case console
    case file(String)
    case memory
    case custom((LogEntry) -> Void)
    
    public static func == (lhs: LogDestination, rhs: LogDestination) -> Bool {
        switch (lhs, rhs) {
        case (.console, .console): return true
        case (.memory, .memory): return true
        case (.file(let a), .file(let b)): return a == b
        default: return false
        }
    }
}

// MARK: - Log Entry

/// Represents a single log entry
public struct LogEntry: Sendable {
    public let timestamp: Date
    public let level: LogLevel
    public let message: String
    public let file: String
    public let function: String
    public let line: UInt
    public let metadata: [String: String]
    
    public init(
        timestamp: Date = Date(),
        level: LogLevel,
        message: String,
        file: String = #file,
        function: String = #function,
        line: UInt = #line,
        metadata: [String: String] = [:]
    ) {
        self.timestamp = timestamp
        self.level = level
        self.message = message
        self.file = file
        self.function = function
        self.line = line
        self.metadata = metadata
    }
    
    public var formattedTimestamp: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd HH:mm:ss.SSS"
        return formatter.string(from: timestamp)
    }
    
    public var fileName: String {
        return URL(fileURLWithPath: file).lastPathComponent
    }
}

// MARK: - Log Formatter

/// Protocol for log formatters
public protocol LogFormatter: Sendable {
    func format(_ entry: LogEntry) -> String
}

/// Default log formatter with colored output
public struct DefaultLogFormatter: LogFormatter, Sendable {
    public let showTimestamp: Bool
    public let showLevel: Bool
    public let showEmoji: Bool
    public let showLocation: Bool
    public let useColors: Bool
    
    public init(
        showTimestamp: Bool = false,
        showLevel: Bool = true,
        showEmoji: Bool = true,
        showLocation: Bool = false,
        useColors: Bool = true
    ) {
        self.showTimestamp = showTimestamp
        self.showLevel = showLevel
        self.showEmoji = showEmoji
        self.showLocation = showLocation
        self.useColors = useColors
    }
    
    public func format(_ entry: LogEntry) -> String {
        var parts: [String] = []
        
        if showTimestamp {
            parts.append("[\(entry.formattedTimestamp)]")
        }
        
        if showEmoji {
            parts.append(entry.level.emoji)
        }
        
        if showLevel {
            let levelStr = entry.level.prefix
            if useColors {
                parts.append(colorize(levelStr, level: entry.level))
            } else {
                parts.append("[\(levelStr)]")
            }
        }
        
        let message = useColors ? colorizeMessage(entry.message, level: entry.level) : entry.message
        parts.append(message)
        
        if showLocation {
            parts.append("(\(entry.fileName):\(entry.line))")
        }
        
        return parts.joined(separator: " ")
    }
    
    private func colorize(_ text: String, level: LogLevel) -> String {
        switch level {
        case .trace: return text.lightBlack
        case .debug: return text.cyan
        case .info: return text.blue
        case .success: return text.green
        case .warning: return text.yellow
        case .error: return text.red
        case .fatal: return text.red.bold
        case .silent: return text
        }
    }
    
    private func colorizeMessage(_ text: String, level: LogLevel) -> String {
        switch level {
        case .error, .fatal: return text.red
        case .warning: return text.yellow
        case .success: return text.green
        default: return text
        }
    }
}

/// JSON log formatter for structured logging
public struct JSONLogFormatter: LogFormatter, Sendable {
    public let prettyPrint: Bool
    
    public init(prettyPrint: Bool = false) {
        self.prettyPrint = prettyPrint
    }
    
    public func format(_ entry: LogEntry) -> String {
        var dict: [String: Any] = [
            "timestamp": entry.formattedTimestamp,
            "level": entry.level.prefix.lowercased(),
            "message": entry.message,
            "file": entry.fileName,
            "function": entry.function,
            "line": entry.line
        ]
        
        if !entry.metadata.isEmpty {
            dict["metadata"] = entry.metadata
        }
        
        guard let data = try? JSONSerialization.data(
            withJSONObject: dict,
            options: prettyPrint ? [.prettyPrinted, .sortedKeys] : [.sortedKeys]
        ) else {
            return "{\"error\": \"Failed to serialize log entry\"}"
        }
        
        return String(data: data, encoding: .utf8) ?? "{}"
    }
}

// MARK: - Logger

/// Main logger class for MobileCI
public final class Logger: @unchecked Sendable {
    public static let shared = Logger()
    
    private var destinations: [LogDestination] = [.console]
    private var formatter: LogFormatter = DefaultLogFormatter()
    private var minimumLevel: LogLevel = .info
    private var memoryLog: [LogEntry] = []
    private let lock = NSLock()
    private var fileHandle: FileHandle?
    private var indentLevel: Int = 0
    
    private init() {}
    
    // MARK: - Configuration
    
    public func configure(
        destinations: [LogDestination] = [.console],
        formatter: LogFormatter? = nil,
        minimumLevel: LogLevel = .info
    ) {
        lock.lock()
        defer { lock.unlock() }
        
        self.destinations = destinations
        if let formatter = formatter {
            self.formatter = formatter
        }
        self.minimumLevel = minimumLevel
        
        // Setup file destination if needed
        for dest in destinations {
            if case .file(let path) = dest {
                setupFileDestination(path)
            }
        }
    }
    
    public func setMinimumLevel(_ level: LogLevel) {
        lock.lock()
        defer { lock.unlock() }
        minimumLevel = level
    }
    
    public func setFormatter(_ formatter: LogFormatter) {
        lock.lock()
        defer { lock.unlock() }
        self.formatter = formatter
    }
    
    private func setupFileDestination(_ path: String) {
        let fileManager = FileManager.default
        let url = URL(fileURLWithPath: path)
        
        // Create directory if needed
        let directory = url.deletingLastPathComponent()
        try? fileManager.createDirectory(at: directory, withIntermediateDirectories: true)
        
        // Create file if needed
        if !fileManager.fileExists(atPath: path) {
            fileManager.createFile(atPath: path, contents: nil)
        }
        
        fileHandle = FileHandle(forWritingAtPath: path)
        fileHandle?.seekToEndOfFile()
    }
    
    // MARK: - Logging Methods
    
    public func log(
        _ level: LogLevel,
        _ message: @autoclosure () -> String,
        metadata: [String: String] = [:],
        file: String = #file,
        function: String = #function,
        line: UInt = #line
    ) {
        guard level >= minimumLevel else { return }
        
        let entry = LogEntry(
            level: level,
            message: message(),
            file: file,
            function: function,
            line: line,
            metadata: metadata
        )
        
        let formattedMessage = formatter.format(entry)
        let indentedMessage = indentLevel > 0 
            ? String(repeating: "  ", count: indentLevel) + formattedMessage 
            : formattedMessage
        
        output(entry: entry, formatted: indentedMessage)
    }
    
    private func output(entry: LogEntry, formatted: String) {
        lock.lock()
        defer { lock.unlock() }
        
        for destination in destinations {
            switch destination {
            case .console:
                print(formatted)
            case .file:
                if let data = (formatted + "\n").data(using: .utf8) {
                    fileHandle?.write(data)
                }
            case .memory:
                memoryLog.append(entry)
            case .custom(let handler):
                handler(entry)
            }
        }
    }
    
    // MARK: - Convenience Methods
    
    public func trace(
        _ message: @autoclosure () -> String,
        metadata: [String: String] = [:],
        file: String = #file,
        function: String = #function,
        line: UInt = #line
    ) {
        log(.trace, message(), metadata: metadata, file: file, function: function, line: line)
    }
    
    public func debug(
        _ message: @autoclosure () -> String,
        metadata: [String: String] = [:],
        file: String = #file,
        function: String = #function,
        line: UInt = #line
    ) {
        log(.debug, message(), metadata: metadata, file: file, function: function, line: line)
    }
    
    public func info(
        _ message: @autoclosure () -> String,
        metadata: [String: String] = [:],
        file: String = #file,
        function: String = #function,
        line: UInt = #line
    ) {
        log(.info, message(), metadata: metadata, file: file, function: function, line: line)
    }
    
    public func success(
        _ message: @autoclosure () -> String,
        metadata: [String: String] = [:],
        file: String = #file,
        function: String = #function,
        line: UInt = #line
    ) {
        log(.success, message(), metadata: metadata, file: file, function: function, line: line)
    }
    
    public func warning(
        _ message: @autoclosure () -> String,
        metadata: [String: String] = [:],
        file: String = #file,
        function: String = #function,
        line: UInt = #line
    ) {
        log(.warning, message(), metadata: metadata, file: file, function: function, line: line)
    }
    
    public func error(
        _ message: @autoclosure () -> String,
        metadata: [String: String] = [:],
        file: String = #file,
        function: String = #function,
        line: UInt = #line
    ) {
        log(.error, message(), metadata: metadata, file: file, function: function, line: line)
    }
    
    public func fatal(
        _ message: @autoclosure () -> String,
        metadata: [String: String] = [:],
        file: String = #file,
        function: String = #function,
        line: UInt = #line
    ) {
        log(.fatal, message(), metadata: metadata, file: file, function: function, line: line)
    }
    
    // MARK: - Structured Logging
    
    public func group(_ title: String, _ block: () throws -> Void) rethrows {
        info("▶ \(title)")
        indent()
        defer { dedent() }
        try block()
    }
    
    public func asyncGroup(_ title: String, _ block: () async throws -> Void) async rethrows {
        info("▶ \(title)")
        indent()
        defer { dedent() }
        try await block()
    }
    
    public func indent() {
        lock.lock()
        defer { lock.unlock() }
        indentLevel += 1
    }
    
    public func dedent() {
        lock.lock()
        defer { lock.unlock() }
        indentLevel = max(0, indentLevel - 1)
    }
    
    // MARK: - Progress
    
    public func progress(_ current: Int, total: Int, message: String = "") {
        let percentage = total > 0 ? Int((Double(current) / Double(total)) * 100) : 0
        let filled = percentage / 5
        let empty = 20 - filled
        let bar = String(repeating: "█", count: filled) + String(repeating: "░", count: empty)
        
        let progressLine = "\r[\(bar)] \(percentage)% \(message)"
        
        lock.lock()
        defer { lock.unlock() }
        
        print(progressLine, terminator: "")
        fflush(stdout)
        
        if current >= total {
            print()
        }
    }
    
    public func spinner(_ message: String, duration: TimeInterval = 0.1) -> SpinnerHandle {
        return SpinnerHandle(message: message, interval: duration)
    }
    
    // MARK: - Memory Log
    
    public func getMemoryLog() -> [LogEntry] {
        lock.lock()
        defer { lock.unlock() }
        return memoryLog
    }
    
    public func clearMemoryLog() {
        lock.lock()
        defer { lock.unlock() }
        memoryLog.removeAll()
    }
    
    // MARK: - Cleanup
    
    public func flush() {
        lock.lock()
        defer { lock.unlock() }
        fileHandle?.synchronizeFile()
    }
    
    deinit {
        fileHandle?.closeFile()
    }
}

// MARK: - Spinner Handle

/// Handle for controlling a spinner animation
public final class SpinnerHandle: @unchecked Sendable {
    private let message: String
    private let interval: TimeInterval
    private var isRunning = false
    private var task: Task<Void, Never>?
    private let frames = ["⠋", "⠙", "⠹", "⠸", "⠼", "⠴", "⠦", "⠧", "⠇", "⠏"]
    
    init(message: String, interval: TimeInterval) {
        self.message = message
        self.interval = interval
    }
    
    public func start() {
        guard !isRunning else { return }
        isRunning = true
        
        task = Task {
            var frameIndex = 0
            while isRunning {
                let frame = frames[frameIndex % frames.count]
                print("\r\(frame) \(message)", terminator: "")
                fflush(stdout)
                frameIndex += 1
                try? await Task.sleep(nanoseconds: UInt64(interval * 1_000_000_000))
            }
        }
    }
    
    public func stop(success: Bool = true) {
        isRunning = false
        task?.cancel()
        task = nil
        
        let icon = success ? "✅" : "❌"
        print("\r\(icon) \(message)")
    }
    
    public func update(_ newMessage: String) {
        print("\r\(frames[0]) \(newMessage)", terminator: "")
        fflush(stdout)
    }
}

// MARK: - Table Formatter

/// Formats data as a table for console output
public struct TableFormatter {
    public struct Column {
        public let header: String
        public let width: Int?
        public let alignment: Alignment
        
        public enum Alignment {
            case left
            case right
            case center
        }
        
        public init(header: String, width: Int? = nil, alignment: Alignment = .left) {
            self.header = header
            self.width = width
            self.alignment = alignment
        }
    }
    
    private let columns: [Column]
    
    public init(columns: [Column]) {
        self.columns = columns
    }
    
    public func format(rows: [[String]]) -> String {
        // Calculate column widths
        var widths = columns.map { col -> Int in
            col.width ?? col.header.count
        }
        
        for row in rows {
            for (index, cell) in row.enumerated() where index < widths.count {
                widths[index] = max(widths[index], cell.count)
            }
        }
        
        var output = ""
        
        // Header
        var headerLine = "│"
        var separatorLine = "├"
        
        for (index, column) in columns.enumerated() {
            let width = widths[index]
            headerLine += " " + pad(column.header, to: width, alignment: column.alignment) + " │"
            separatorLine += String(repeating: "─", count: width + 2)
            separatorLine += index < columns.count - 1 ? "┼" : "┤"
        }
        
        // Top border
        var topBorder = "┌"
        for (index, width) in widths.enumerated() {
            topBorder += String(repeating: "─", count: width + 2)
            topBorder += index < widths.count - 1 ? "┬" : "┐"
        }
        
        // Bottom border
        var bottomBorder = "└"
        for (index, width) in widths.enumerated() {
            bottomBorder += String(repeating: "─", count: width + 2)
            bottomBorder += index < widths.count - 1 ? "┴" : "┘"
        }
        
        output += topBorder + "\n"
        output += headerLine + "\n"
        output += separatorLine + "\n"
        
        // Rows
        for row in rows {
            var rowLine = "│"
            for (index, cell) in row.enumerated() where index < columns.count {
                let width = widths[index]
                let alignment = columns[index].alignment
                rowLine += " " + pad(cell, to: width, alignment: alignment) + " │"
            }
            output += rowLine + "\n"
        }
        
        output += bottomBorder
        
        return output
    }
    
    private func pad(_ text: String, to width: Int, alignment: Column.Alignment) -> String {
        let padding = max(0, width - text.count)
        
        switch alignment {
        case .left:
            return text + String(repeating: " ", count: padding)
        case .right:
            return String(repeating: " ", count: padding) + text
        case .center:
            let left = padding / 2
            let right = padding - left
            return String(repeating: " ", count: left) + text + String(repeating: " ", count: right)
        }
    }
}

// MARK: - Global Logging Functions

/// Convenience function for trace logging
public func logTrace(_ message: @autoclosure () -> String, file: String = #file, function: String = #function, line: UInt = #line) {
    Logger.shared.trace(message(), file: file, function: function, line: line)
}

/// Convenience function for debug logging
public func logDebug(_ message: @autoclosure () -> String, file: String = #file, function: String = #function, line: UInt = #line) {
    Logger.shared.debug(message(), file: file, function: function, line: line)
}

/// Convenience function for info logging
public func logInfo(_ message: @autoclosure () -> String, file: String = #file, function: String = #function, line: UInt = #line) {
    Logger.shared.info(message(), file: file, function: function, line: line)
}

/// Convenience function for success logging
public func logSuccess(_ message: @autoclosure () -> String, file: String = #file, function: String = #function, line: UInt = #line) {
    Logger.shared.success(message(), file: file, function: function, line: line)
}

/// Convenience function for warning logging
public func logWarning(_ message: @autoclosure () -> String, file: String = #file, function: String = #function, line: UInt = #line) {
    Logger.shared.warning(message(), file: file, function: function, line: line)
}

/// Convenience function for error logging
public func logError(_ message: @autoclosure () -> String, file: String = #file, function: String = #function, line: UInt = #line) {
    Logger.shared.error(message(), file: file, function: function, line: line)
}

/// Convenience function for fatal logging
public func logFatal(_ message: @autoclosure () -> String, file: String = #file, function: String = #function, line: UInt = #line) {
    Logger.shared.fatal(message(), file: file, function: function, line: line)
}
