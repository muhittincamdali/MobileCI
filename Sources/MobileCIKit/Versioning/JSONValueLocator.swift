/// Finds where a value sits in JSON text, so it can be replaced without re-serialising the
/// file (which would reorder keys and change its formatting).
///
/// The text must already have been parsed by `JSONSerialization`; this scanner only walks it.
/// It is iterative, stops at ``maximumDepth`` and returns `nil` for anything unexpected.
enum JSONValueLocator {
    static let maximumDepth = 64

    struct Match: Equatable {
        /// The value without quotes for a string, the digits for a number.
        let range: Range<String.Index>
        let isString: Bool
    }

    private enum Container {
        case object(expectingKey: Bool)
        case array
    }

    /// The value at `path` (`["expo", "ios", "buildNumber"]`). Only strings without escapes
    /// and plain numbers are returned.
    static func find(_ path: [String], in text: String) -> Match? {
        let scalars = text.unicodeScalars
        var index = scalars.startIndex
        var containers: [Container] = []
        var keys: [String?] = []
        var pendingKey: String?

        func skipWhitespace() {
            while index < scalars.endIndex, [" ", "\n", "\r", "\t"].contains(scalars[index]) {
                index = scalars.index(after: index)
            }
        }

        /// Reads a string starting at the opening quote; returns its content range and whether
        /// it contains escapes.
        func readString() -> (range: Range<String.Index>, escaped: Bool)? {
            index = scalars.index(after: index)
            let start = index
            var escaped = false
            while index < scalars.endIndex {
                let scalar = scalars[index]
                if scalar == "\\" {
                    escaped = true
                    index = scalars.index(after: index)
                    guard index < scalars.endIndex else { return nil }
                } else if scalar == "\"" {
                    let range = start..<index
                    index = scalars.index(after: index)
                    return (range, escaped)
                }
                index = scalars.index(after: index)
            }
            return nil
        }

        while true {
            skipWhitespace()
            guard index < scalars.endIndex else { return nil }
            let scalar = scalars[index]
            // The root container has no key; a container inside an array gets a marker that no
            // path contains, so `{"a":[{"b":1}]}` never matches `["a", "b"]`.
            let currentPath = keys.dropFirst().map { $0 ?? "\u{1}" } + (pendingKey.map { [$0] } ?? [])
            let isTarget = pendingKey != nil && currentPath == path

            if case .object(expectingKey: true)? = containers.last, scalar == "\"" {
                guard let key = readString() else { return nil }
                pendingKey = key.escaped ? "\u{0}" : String(text[key.range])
                containers[containers.count - 1] = .object(expectingKey: false)
                skipWhitespace()
                guard index < scalars.endIndex, scalars[index] == ":" else { return nil }
                index = scalars.index(after: index)
                continue
            }
            switch scalar {
            case "{", "[":
                guard containers.count < maximumDepth else { return nil }
                keys.append(pendingKey)
                pendingKey = nil
                containers.append(scalar == "{" ? .object(expectingKey: true) : .array)
                index = scalars.index(after: index)
            case "}", "]":
                guard !containers.isEmpty else { return nil }
                containers.removeLast()
                keys.removeLast()
                pendingKey = nil
                index = scalars.index(after: index)
                if containers.isEmpty { return nil }
            case ",":
                if case .object? = containers.last { containers[containers.count - 1] = .object(expectingKey: true) }
                pendingKey = nil
                index = scalars.index(after: index)
            case "\"":
                guard let value = readString() else { return nil }
                if isTarget { return value.escaped ? nil : Match(range: value.range, isString: true) }
                pendingKey = nil
            default:
                let start = index
                while index < scalars.endIndex, !([",", "}", "]", " ", "\n", "\r", "\t"].contains(scalars[index])) {
                    index = scalars.index(after: index)
                }
                if isTarget { return Match(range: start..<index, isString: false) }
                pendingKey = nil
            }
        }
    }
}
