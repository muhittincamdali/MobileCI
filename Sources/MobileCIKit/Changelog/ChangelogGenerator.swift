// ChangelogGenerator.swift
// MobileCIKit
//
// Automatic changelog generation from git commits.
// Supports conventional commits, keep-a-changelog format, and release notes.

import Foundation

// MARK: - Commit Type

/// Types of commits based on conventional commits spec
public enum CommitType: String, CaseIterable, Codable, Sendable {
    case feat = "feat"
    case fix = "fix"
    case docs = "docs"
    case style = "style"
    case refactor = "refactor"
    case perf = "perf"
    case test = "test"
    case build = "build"
    case ci = "ci"
    case chore = "chore"
    case revert = "revert"
    case breaking = "breaking"
    
    public var displayName: String {
        switch self {
        case .feat: return "Features"
        case .fix: return "Bug Fixes"
        case .docs: return "Documentation"
        case .style: return "Styles"
        case .refactor: return "Code Refactoring"
        case .perf: return "Performance Improvements"
        case .test: return "Tests"
        case .build: return "Build System"
        case .ci: return "Continuous Integration"
        case .chore: return "Chores"
        case .revert: return "Reverts"
        case .breaking: return "BREAKING CHANGES"
        }
    }
    
    public var emoji: String {
        switch self {
        case .feat: return "✨"
        case .fix: return "🐛"
        case .docs: return "📚"
        case .style: return "💄"
        case .refactor: return "♻️"
        case .perf: return "⚡️"
        case .test: return "✅"
        case .build: return "🔧"
        case .ci: return "👷"
        case .chore: return "🔨"
        case .revert: return "⏪"
        case .breaking: return "💥"
        }
    }
    
    public var priority: Int {
        switch self {
        case .breaking: return 0
        case .feat: return 1
        case .fix: return 2
        case .perf: return 3
        case .refactor: return 4
        case .docs: return 5
        case .style: return 6
        case .test: return 7
        case .build: return 8
        case .ci: return 9
        case .chore: return 10
        case .revert: return 11
        }
    }
}

// MARK: - Parsed Commit

/// Represents a parsed conventional commit
public struct ParsedCommit: Sendable {
    public let hash: String
    public let shortHash: String
    public let type: CommitType
    public let scope: String?
    public let subject: String
    public let body: String?
    public let footer: String?
    public let isBreaking: Bool
    public let author: String
    public let date: Date
    public let references: [String]
    
    public var fullMessage: String {
        var message = "\(type.rawValue)"
        if let scope = scope {
            message += "(\(scope))"
        }
        if isBreaking {
            message += "!"
        }
        message += ": \(subject)"
        return message
    }
}

// MARK: - Changelog Entry

/// Represents a changelog entry for a version
public struct ChangelogEntry: Sendable {
    public let version: String
    public let date: Date
    public let commits: [ParsedCommit]
    public let compareUrl: String?
    
    public var groupedCommits: [CommitType: [ParsedCommit]] {
        var groups: [CommitType: [ParsedCommit]] = [:]
        
        for commit in commits {
            if groups[commit.type] == nil {
                groups[commit.type] = []
            }
            groups[commit.type]?.append(commit)
        }
        
        // Add breaking changes as a separate group
        let breakingCommits = commits.filter { $0.isBreaking }
        if !breakingCommits.isEmpty {
            groups[.breaking] = breakingCommits
        }
        
        return groups
    }
    
    public var sortedTypes: [CommitType] {
        return groupedCommits.keys.sorted { $0.priority < $1.priority }
    }
}

// MARK: - Changelog Format

/// Output format for changelogs
public enum ChangelogFormat: String, CaseIterable, Sendable {
    case markdown = "markdown"
    case keepAChangelog = "keep-a-changelog"
    case plain = "plain"
    case json = "json"
    case html = "html"
    case releaseNotes = "release-notes"
    case slack = "slack"
}

// MARK: - Changelog Configuration

/// Configuration for changelog generation
public struct ChangelogConfig: Codable, Sendable {
    public var repoUrl: String?
    public var includeCommitHash: Bool
    public var includeAuthor: Bool
    public var includeDate: Bool
    public var includeLinks: Bool
    public var useEmoji: Bool
    public var includedTypes: [CommitType]
    public var groupByScope: Bool
    public var maxCommits: Int?
    
    public static let `default` = ChangelogConfig(
        repoUrl: nil,
        includeCommitHash: true,
        includeAuthor: false,
        includeDate: true,
        includeLinks: true,
        useEmoji: true,
        includedTypes: [.feat, .fix, .perf, .refactor, .breaking],
        groupByScope: false,
        maxCommits: nil
    )
    
    public init(
        repoUrl: String? = nil,
        includeCommitHash: Bool = true,
        includeAuthor: Bool = false,
        includeDate: Bool = true,
        includeLinks: Bool = true,
        useEmoji: Bool = true,
        includedTypes: [CommitType] = CommitType.allCases,
        groupByScope: Bool = false,
        maxCommits: Int? = nil
    ) {
        self.repoUrl = repoUrl
        self.includeCommitHash = includeCommitHash
        self.includeAuthor = includeAuthor
        self.includeDate = includeDate
        self.includeLinks = includeLinks
        self.useEmoji = useEmoji
        self.includedTypes = includedTypes
        self.groupByScope = groupByScope
        self.maxCommits = maxCommits
    }
}

// MARK: - Changelog Generator

/// Generates changelogs from git history
public final class ChangelogGenerator: @unchecked Sendable {
    public static let shared = ChangelogGenerator()
    
    private let processRunner = ProcessRunner.shared
    private let logger = Logger.shared
    
    private init() {}
    
    // MARK: - Git Operations
    
    /// Get commits between two references
    public func getCommitsBetween(from: String?, to: String = "HEAD") throws -> [ParsedCommit] {
        var command = "git log"
        
        if let from = from {
            command += " \(from)..\(to)"
        } else {
            command += " \(to)"
        }
        
        command += " --pretty=format:'%H|%h|%s|%b|%an|%aI' --no-merges"
        
        let result = try processRunner.run(command)
        guard result.success else {
            throw ChangelogError.gitCommandFailed(result.stderr)
        }
        
        let lines = result.stdout.components(separatedBy: "\n").filter { !$0.isEmpty }
        return lines.compactMap { parseCommitLine($0) }
    }
    
    /// Get commits since a tag
    public func getCommitsSinceTag(_ tag: String) throws -> [ParsedCommit] {
        return try getCommitsBetween(from: tag, to: "HEAD")
    }
    
    /// Get commits for a version range
    public func getCommitsForVersion(from: String, to: String) throws -> [ParsedCommit] {
        return try getCommitsBetween(from: from, to: to)
    }
    
    /// Get all tags sorted by version
    public func getTags() throws -> [String] {
        let result = try processRunner.run("git tag --sort=-v:refname")
        guard result.success else {
            throw ChangelogError.gitCommandFailed(result.stderr)
        }
        
        return result.stdout.components(separatedBy: "\n").filter { !$0.isEmpty }
    }
    
    /// Get the latest tag
    public func getLatestTag() throws -> String? {
        let tags = try getTags()
        return tags.first
    }
    
    // MARK: - Commit Parsing
    
    private func parseCommitLine(_ line: String) -> ParsedCommit? {
        let parts = line.components(separatedBy: "|")
        guard parts.count >= 5 else { return nil }
        
        let hash = parts[0].trimmingCharacters(in: .init(charactersIn: "'"))
        let shortHash = parts[1]
        let subject = parts[2]
        let body = parts.count > 3 ? parts[3] : nil
        let author = parts[4]
        let dateString = parts.count > 5 ? parts[5].trimmingCharacters(in: .init(charactersIn: "'")) : nil
        
        // Parse conventional commit format: type(scope): subject
        let pattern = #"^(\w+)(?:\(([^)]+)\))?(!)?:\s*(.+)$"#
        
        guard let regex = try? NSRegularExpression(pattern: pattern),
              let match = regex.firstMatch(in: subject, range: NSRange(subject.startIndex..., in: subject)) else {
            // Not a conventional commit, categorize as chore
            return ParsedCommit(
                hash: hash,
                shortHash: shortHash,
                type: .chore,
                scope: nil,
                subject: subject,
                body: body,
                footer: nil,
                isBreaking: false,
                author: author,
                date: parseDate(dateString) ?? Date(),
                references: extractReferences(from: subject + (body ?? ""))
            )
        }
        
        func getString(_ index: Int) -> String? {
            guard let range = Range(match.range(at: index), in: subject) else { return nil }
            return String(subject[range])
        }
        
        let typeStr = getString(1) ?? "chore"
        let scope = getString(2)
        let breakingIndicator = getString(3)
        let message = getString(4) ?? subject
        
        let type = CommitType(rawValue: typeStr) ?? .chore
        let isBreaking = breakingIndicator != nil || body?.contains("BREAKING CHANGE") == true
        
        return ParsedCommit(
            hash: hash,
            shortHash: shortHash,
            type: type,
            scope: scope,
            subject: message,
            body: body,
            footer: nil,
            isBreaking: isBreaking,
            author: author,
            date: parseDate(dateString) ?? Date(),
            references: extractReferences(from: subject + (body ?? ""))
        )
    }
    
    private func parseDate(_ dateString: String?) -> Date? {
        guard let dateString = dateString else { return nil }
        
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime]
        return formatter.date(from: dateString)
    }
    
    private func extractReferences(from text: String) -> [String] {
        let pattern = #"#(\d+)"#
        guard let regex = try? NSRegularExpression(pattern: pattern) else { return [] }
        
        let matches = regex.matches(in: text, range: NSRange(text.startIndex..., in: text))
        return matches.compactMap { match -> String? in
            guard let range = Range(match.range(at: 1), in: text) else { return nil }
            return String(text[range])
        }
    }
    
    // MARK: - Changelog Generation
    
    /// Generate changelog for a specific version
    public func generateChangelog(
        version: String,
        from: String? = nil,
        to: String = "HEAD",
        config: ChangelogConfig = .default,
        format: ChangelogFormat = .markdown
    ) throws -> String {
        let commits = try getCommitsBetween(from: from, to: to)
        let filteredCommits = commits.filter { config.includedTypes.contains($0.type) }
        
        let entry = ChangelogEntry(
            version: version,
            date: Date(),
            commits: Array(filteredCommits.prefix(config.maxCommits ?? Int.max)),
            compareUrl: generateCompareUrl(from: from, to: to, config: config)
        )
        
        return formatChangelog(entry: entry, config: config, format: format)
    }
    
    /// Generate full changelog from all tags
    public func generateFullChangelog(
        config: ChangelogConfig = .default,
        format: ChangelogFormat = .keepAChangelog
    ) throws -> String {
        let tags = try getTags()
        
        var entries: [ChangelogEntry] = []
        var previousTag: String? = nil
        
        for tag in tags.reversed() {
            let commits = try getCommitsBetween(from: previousTag, to: tag)
            let filteredCommits = commits.filter { config.includedTypes.contains($0.type) }
            
            if !filteredCommits.isEmpty {
                let entry = ChangelogEntry(
                    version: tag,
                    date: filteredCommits.first?.date ?? Date(),
                    commits: filteredCommits,
                    compareUrl: generateCompareUrl(from: previousTag, to: tag, config: config)
                )
                entries.append(entry)
            }
            
            previousTag = tag
        }
        
        // Add unreleased changes
        if let latestTag = tags.first {
            let unreleasedCommits = try getCommitsBetween(from: latestTag, to: "HEAD")
            let filteredUnreleased = unreleasedCommits.filter { config.includedTypes.contains($0.type) }
            
            if !filteredUnreleased.isEmpty {
                let unreleasedEntry = ChangelogEntry(
                    version: "Unreleased",
                    date: Date(),
                    commits: filteredUnreleased,
                    compareUrl: generateCompareUrl(from: latestTag, to: "HEAD", config: config)
                )
                entries.insert(unreleasedEntry, at: 0)
            }
        }
        
        return formatFullChangelog(entries: entries.reversed(), config: config, format: format)
    }
    
    // MARK: - Formatting
    
    private func formatChangelog(
        entry: ChangelogEntry,
        config: ChangelogConfig,
        format: ChangelogFormat
    ) -> String {
        switch format {
        case .markdown:
            return formatMarkdown(entry: entry, config: config)
        case .keepAChangelog:
            return formatKeepAChangelog(entry: entry, config: config)
        case .plain:
            return formatPlain(entry: entry, config: config)
        case .json:
            return formatJSON(entry: entry, config: config)
        case .html:
            return formatHTML(entry: entry, config: config)
        case .releaseNotes:
            return formatReleaseNotes(entry: entry, config: config)
        case .slack:
            return formatSlack(entry: entry, config: config)
        }
    }
    
    private func formatFullChangelog(
        entries: [ChangelogEntry],
        config: ChangelogConfig,
        format: ChangelogFormat
    ) -> String {
        var output = ""
        
        switch format {
        case .keepAChangelog:
            output = """
                # Changelog
                
                All notable changes to this project will be documented in this file.
                
                The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
                and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).
                
                
                """
        case .markdown:
            output = "# Changelog\n\n"
        default:
            break
        }
        
        for entry in entries {
            output += formatChangelog(entry: entry, config: config, format: format)
            output += "\n"
        }
        
        return output
    }
    
    private func formatMarkdown(entry: ChangelogEntry, config: ChangelogConfig) -> String {
        var output = ""
        
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        let dateString = dateFormatter.string(from: entry.date)
        
        output += "## \(entry.version)"
        if config.includeDate {
            output += " (\(dateString))"
        }
        output += "\n\n"
        
        for type in entry.sortedTypes {
            guard let commits = entry.groupedCommits[type], !commits.isEmpty else { continue }
            
            let prefix = config.useEmoji ? "\(type.emoji) " : ""
            output += "### \(prefix)\(type.displayName)\n\n"
            
            for commit in commits {
                output += "- "
                if let scope = commit.scope {
                    output += "**\(scope):** "
                }
                output += commit.subject
                
                if config.includeCommitHash {
                    if let repoUrl = config.repoUrl, config.includeLinks {
                        output += " ([\(commit.shortHash)](\(repoUrl)/commit/\(commit.hash)))"
                    } else {
                        output += " (\(commit.shortHash))"
                    }
                }
                
                if config.includeAuthor {
                    output += " by @\(commit.author)"
                }
                
                // Add issue references
                if config.includeLinks, let repoUrl = config.repoUrl {
                    for ref in commit.references {
                        output += " [#\(ref)](\(repoUrl)/issues/\(ref))"
                    }
                }
                
                output += "\n"
            }
            
            output += "\n"
        }
        
        return output
    }
    
    private func formatKeepAChangelog(entry: ChangelogEntry, config: ChangelogConfig) -> String {
        var output = ""
        
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        let dateString = dateFormatter.string(from: entry.date)
        
        if entry.version == "Unreleased" {
            output += "## [Unreleased]\n\n"
        } else {
            if let compareUrl = entry.compareUrl, config.includeLinks {
                output += "## [\(entry.version)](\(compareUrl)) - \(dateString)\n\n"
            } else {
                output += "## [\(entry.version)] - \(dateString)\n\n"
            }
        }
        
        // Map commit types to Keep a Changelog categories
        let typeMapping: [CommitType: String] = [
            .feat: "Added",
            .fix: "Fixed",
            .perf: "Changed",
            .refactor: "Changed",
            .breaking: "Changed",
            .docs: "Changed",
            .revert: "Removed"
        ]
        
        var categories: [String: [ParsedCommit]] = [:]
        
        for type in entry.sortedTypes {
            guard let commits = entry.groupedCommits[type] else { continue }
            let category = typeMapping[type] ?? "Changed"
            
            if categories[category] == nil {
                categories[category] = []
            }
            categories[category]?.append(contentsOf: commits)
        }
        
        for category in ["Added", "Changed", "Deprecated", "Removed", "Fixed", "Security"] {
            guard let commits = categories[category], !commits.isEmpty else { continue }
            
            output += "### \(category)\n\n"
            
            for commit in commits {
                output += "- "
                if let scope = commit.scope {
                    output += "**\(scope):** "
                }
                output += commit.subject
                output += "\n"
            }
            
            output += "\n"
        }
        
        return output
    }
    
    private func formatPlain(entry: ChangelogEntry, config: ChangelogConfig) -> String {
        var output = ""
        
        output += "Version \(entry.version)\n"
        output += String(repeating: "=", count: 50) + "\n\n"
        
        for type in entry.sortedTypes {
            guard let commits = entry.groupedCommits[type], !commits.isEmpty else { continue }
            
            output += "\(type.displayName):\n"
            
            for commit in commits {
                output += "  * "
                if let scope = commit.scope {
                    output += "[\(scope)] "
                }
                output += commit.subject
                output += "\n"
            }
            
            output += "\n"
        }
        
        return output
    }
    
    private func formatJSON(entry: ChangelogEntry, config: ChangelogConfig) -> String {
        var dict: [String: Any] = [
            "version": entry.version,
            "date": ISO8601DateFormatter().string(from: entry.date),
            "changes": [:]
        ]
        
        var changes: [String: [[String: Any]]] = [:]
        
        for type in entry.sortedTypes {
            guard let commits = entry.groupedCommits[type] else { continue }
            
            changes[type.rawValue] = commits.map { commit in
                var commitDict: [String: Any] = [
                    "subject": commit.subject,
                    "hash": commit.hash,
                    "shortHash": commit.shortHash,
                    "author": commit.author,
                    "isBreaking": commit.isBreaking
                ]
                if let scope = commit.scope {
                    commitDict["scope"] = scope
                }
                return commitDict
            }
        }
        
        dict["changes"] = changes
        
        guard let data = try? JSONSerialization.data(withJSONObject: dict, options: [.prettyPrinted, .sortedKeys]),
              let json = String(data: data, encoding: .utf8) else {
            return "{}"
        }
        
        return json
    }
    
    private func formatHTML(entry: ChangelogEntry, config: ChangelogConfig) -> String {
        var output = """
            <div class="changelog-entry">
              <h2>\(entry.version)</h2>
            
            """
        
        for type in entry.sortedTypes {
            guard let commits = entry.groupedCommits[type], !commits.isEmpty else { continue }
            
            output += "  <h3>\(config.useEmoji ? type.emoji + " " : "")\(type.displayName)</h3>\n"
            output += "  <ul>\n"
            
            for commit in commits {
                output += "    <li>"
                if let scope = commit.scope {
                    output += "<strong>\(scope):</strong> "
                }
                output += commit.subject
                output += "</li>\n"
            }
            
            output += "  </ul>\n"
        }
        
        output += "</div>\n"
        
        return output
    }
    
    private func formatReleaseNotes(entry: ChangelogEntry, config: ChangelogConfig) -> String {
        var output = ""
        
        // Features first
        if let features = entry.groupedCommits[.feat], !features.isEmpty {
            output += "🚀 What's New\n"
            for commit in features {
                output += "• \(commit.subject)\n"
            }
            output += "\n"
        }
        
        // Bug fixes
        if let fixes = entry.groupedCommits[.fix], !fixes.isEmpty {
            output += "🐛 Bug Fixes\n"
            for commit in fixes {
                output += "• \(commit.subject)\n"
            }
            output += "\n"
        }
        
        // Performance
        if let perf = entry.groupedCommits[.perf], !perf.isEmpty {
            output += "⚡️ Performance Improvements\n"
            for commit in perf {
                output += "• \(commit.subject)\n"
            }
            output += "\n"
        }
        
        // Breaking changes
        if let breaking = entry.groupedCommits[.breaking], !breaking.isEmpty {
            output += "⚠️ Breaking Changes\n"
            for commit in breaking {
                output += "• \(commit.subject)\n"
            }
            output += "\n"
        }
        
        return output.trimmingCharacters(in: .whitespacesAndNewlines)
    }
    
    private func formatSlack(entry: ChangelogEntry, config: ChangelogConfig) -> String {
        var output = ""
        
        output += "*\(entry.version)* released! 🎉\n\n"
        
        for type in entry.sortedTypes {
            guard let commits = entry.groupedCommits[type], !commits.isEmpty else { continue }
            
            output += "*\(type.emoji) \(type.displayName)*\n"
            
            for commit in commits {
                output += "• \(commit.subject)\n"
            }
            
            output += "\n"
        }
        
        return output
    }
    
    private func generateCompareUrl(from: String?, to: String, config: ChangelogConfig) -> String? {
        guard let repoUrl = config.repoUrl else { return nil }
        
        if let from = from {
            return "\(repoUrl)/compare/\(from)...\(to)"
        }
        return nil
    }
    
    // MARK: - File Operations
    
    /// Update CHANGELOG.md file
    public func updateChangelogFile(
        path: String = "CHANGELOG.md",
        version: String,
        from: String? = nil,
        config: ChangelogConfig = .default
    ) throws {
        let newEntry = try generateChangelog(
            version: version,
            from: from,
            config: config,
            format: .keepAChangelog
        )
        
        var content: String
        
        if FileManager.default.fileExists(atPath: path) {
            content = try String(contentsOfFile: path, encoding: .utf8)
            
            // Insert new entry after the header
            if let range = content.range(of: "## [") {
                content.insert(contentsOf: newEntry + "\n", at: range.lowerBound)
            } else {
                content += "\n" + newEntry
            }
        } else {
            // Create new file
            content = """
                # Changelog
                
                All notable changes to this project will be documented in this file.
                
                The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
                and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).
                
                \(newEntry)
                """
        }
        
        try content.write(toFile: path, atomically: true, encoding: .utf8)
        logger.success("Updated \(path)")
    }
}

// MARK: - Changelog Errors

/// Errors that can occur during changelog generation
public enum ChangelogError: LocalizedError {
    case gitCommandFailed(String)
    case parseError(String)
    case fileWriteError(String)
    
    public var errorDescription: String? {
        switch self {
        case .gitCommandFailed(let message):
            return "Git command failed: \(message)"
        case .parseError(let message):
            return "Parse error: \(message)"
        case .fileWriteError(let message):
            return "File write error: \(message)"
        }
    }
}
