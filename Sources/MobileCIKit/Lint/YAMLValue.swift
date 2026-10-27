import Foundation
import Yams

/// A 1-based line and column in a source file.
public struct SourceLocation: Sendable, Hashable, Comparable, Codable {
    public let line: Int
    public let column: Int

    public init(line: Int, column: Int) {
        self.line = line
        self.column = column
    }

    public static func < (lhs: SourceLocation, rhs: SourceLocation) -> Bool {
        (lhs.line, lhs.column) < (rhs.line, rhs.column)
    }

    static let start = SourceLocation(line: 1, column: 1)
}

/// A YAML node with the location it was read from. Scalars keep their text: `on`, `true` and
/// `1` stay strings, the way GitHub Actions reads workflow keys.
public indirect enum YAMLValue: Sendable {
    case scalar(String, SourceLocation)
    case sequence([YAMLValue], SourceLocation)
    case mapping([YAMLMember], SourceLocation)

    public var location: SourceLocation {
        switch self {
        case .scalar(_, let location), .sequence(_, let location), .mapping(_, let location):
            return location
        }
    }

    /// The text of a scalar; `nil` for a sequence or a mapping.
    public var string: String? {
        if case .scalar(let text, _) = self { return text }
        return nil
    }

    /// The members of a mapping; empty for other nodes.
    public var members: [YAMLMember] {
        if case .mapping(let members, _) = self { return members }
        return []
    }

    /// The items of a sequence; empty for other nodes.
    public var items: [YAMLValue] {
        if case .sequence(let items, _) = self { return items }
        return []
    }

    public var isMapping: Bool {
        if case .mapping = self { return true }
        return false
    }

    /// The value of the first member named `key` in a mapping.
    public subscript(key: String) -> YAMLValue? {
        members.first { $0.key == key }?.value
    }

    /// The member named `key` in a mapping, with the location of its key.
    public func member(_ key: String) -> YAMLMember? {
        members.first { $0.key == key }
    }
}

/// A key and its value in a YAML mapping.
public struct YAMLMember: Sendable {
    public let key: String
    public let keyLocation: SourceLocation
    public let value: YAMLValue
}

/// Why a YAML document could not be loaded. No case carries text from the document: parser
/// messages quote the input, which may hold secrets, so only positions are kept.
public enum YAMLLoadError: Error, Equatable, Sendable {
    case syntax(SourceLocation?)
    /// A key that appears twice in one mapping, at the first key Yams reports. The key itself
    /// is not kept: it can be any text, a token included.
    case duplicateKey(SourceLocation?)
    case tooDeep(limit: Int)
    case tooManyNodes(limit: Int)
    /// More than `limit` UTF-8 bytes of scalar text after alias expansion (4 MiB).
    case tooMuchText(limit: Int)
    case empty
}

/// Loads YAML into ``YAMLValue`` trees with fixed limits.
enum YAMLLoader {
    /// Workflows nest about eight levels deep; anything past this is not a workflow.
    static let maximumDepth = 64

    /// Aliases share nodes, so a small document can describe a tree with billions of nodes
    /// ("billion laughs"). Expansion stops at this many nodes.
    static let maximumNodes = 200_000

    /// One long anchored value repeated through aliases stays under the node limit but makes
    /// the rules read its text once per alias. Expansion stops at this much scalar text: four
    /// times the largest file that is read, enough for a script reused across a few jobs.
    static let maximumTextBytes = 4 * TextFile.defaultLimit

    static func load(_ text: String) -> Result<YAMLValue, YAMLLoadError> {
        LargeStack.run { loadOnCurrentThread(text) }
    }

    private static func loadOnCurrentThread(_ text: String) -> Result<YAMLValue, YAMLLoadError> {
        let root: Node?
        do {
            root = try Yams.compose(yaml: text, .basic)
        } catch let error as YamlError {
            return .failure(loadError(from: error))
        } catch {
            return .failure(.syntax(nil))
        }
        guard let root else { return .failure(.empty) }
        var converter = Converter()
        do {
            return .success(try converter.convert(root, depth: 0))
        } catch {
            return .failure(error)
        }
    }

    private static func loadError(from error: YamlError) -> YAMLLoadError {
        switch error {
        case .scanner(_, _, let mark, _), .parser(_, _, let mark, _), .composer(_, _, let mark, _):
            return .syntax(SourceLocation(line: mark.line, column: mark.column))
        case .duplicatedKeysInMapping(_, let context):
            // Yams uses line 0 when the key node has no position.
            let mark = context.mark
            return .duplicateKey(mark.line > 0 ? SourceLocation(line: mark.line, column: mark.column) : nil)
        default:
            return .syntax(nil)
        }
    }

    private struct Converter {
        var visited = 0
        var textBytes = 0

        mutating func convert(_ node: Node, depth: Int) throws(YAMLLoadError) -> YAMLValue {
            visited += 1
            guard visited <= YAMLLoader.maximumNodes else {
                throw .tooManyNodes(limit: YAMLLoader.maximumNodes)
            }
            guard depth <= YAMLLoader.maximumDepth else {
                throw .tooDeep(limit: YAMLLoader.maximumDepth)
            }
            let location = node.mark.map { SourceLocation(line: $0.line, column: $0.column) } ?? .start
            switch node {
            case .scalar(let scalar):
                textBytes += scalar.string.utf8.count
                guard textBytes <= YAMLLoader.maximumTextBytes else {
                    throw .tooMuchText(limit: YAMLLoader.maximumTextBytes)
                }
                // A literal block (`run: |`) starts on the line after its indicator, so line
                // offsets counted in its text land on the right source lines.
                if scalar.style == .literal {
                    return .scalar(scalar.string, SourceLocation(line: location.line + 1, column: 1))
                }
                return .scalar(scalar.string, location)
            case .alias:
                // Yams resolves aliases while composing; an unresolved one has no content.
                return .scalar("", location)
            case .sequence(let sequence):
                var items: [YAMLValue] = []
                for item in sequence {
                    items.append(try convert(item, depth: depth + 1))
                }
                return .sequence(items, location)
            case .mapping(let mapping):
                var members: [YAMLMember] = []
                for (key, value) in mapping {
                    let keyValue = try convert(key, depth: depth + 1)
                    // A complex key (a mapping used as a key) has no name a workflow can use.
                    let name = keyValue.string ?? ""
                    members.append(YAMLMember(
                        key: name,
                        keyLocation: keyValue.location,
                        value: try convert(value, depth: depth + 1)
                    ))
                }
                return .mapping(members, location)
            }
        }
    }
}
