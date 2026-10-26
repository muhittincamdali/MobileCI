import Foundation

/// `${{ … }}` expressions inside a workflow string.
enum Expressions {
    /// One expression with the 0-based line it starts on, counted from the start of the string.
    struct Occurrence: Equatable {
        let body: String
        let lineOffset: Int
    }

    /// Every `${{ … }}` in `text`. An unterminated `${{` ends the scan. Linear in the length of
    /// the text.
    static func occurrences(in text: String) -> [Occurrence] {
        var result: [Occurrence] = []
        var lineOffset = 0
        var index = text.startIndex
        while index < text.endIndex {
            if text[index] == "\n" {
                lineOffset += 1
                index = text.index(after: index)
                continue
            }
            guard text[index...].hasPrefix("${{") else {
                index = text.index(after: index)
                continue
            }
            let bodyStart = text.index(index, offsetBy: 3)
            guard let close = text.range(of: "}}", range: bodyStart..<text.endIndex) else { break }
            let body = String(text[bodyStart..<close.lowerBound])
            result.append(Occurrence(body: body, lineOffset: lineOffset))
            lineOffset += body.reduce(0) { $1 == "\n" ? $0 + 1 : $0 }
            index = close.upperBound
        }
        return result
    }

    /// The context property paths an expression reads, normalised but in their written case
    /// (contexts are case-insensitive, so callers compare lowercased):
    /// `github.event['pull_request'].title` and `github.event.pull_request.title` both give
    /// `github.event.pull_request.title`; an index or `*` gives `*`.
    static func propertyPaths(in body: String) -> [String] {
        var paths: [String] = []
        var current = ""
        var inBrackets = false
        var bracketContent = ""
        var quote: Character?
        var inStringLiteral = false

        func finish() {
            if !current.isEmpty { paths.append(current) }
            current = ""
        }

        for character in body {
            // 'text' is a string literal in the expression language, not a property path.
            if inStringLiteral {
                if character == "'" { inStringLiteral = false }
                continue
            }
            if inBrackets {
                if let open = quote {
                    if character == open { quote = nil } else { bracketContent.append(character) }
                } else if character == "'" || character == "\"" {
                    quote = character
                } else if character == "]" {
                    inBrackets = false
                    let segment = bracketContent.allSatisfy(\.isNumber) || bracketContent == "*" ? "*" : bracketContent
                    current += current.isEmpty ? segment : "." + segment
                    bracketContent = ""
                } else if !character.isWhitespace {
                    bracketContent.append(character)
                }
                continue
            }
            if character == "'" {
                finish()
                inStringLiteral = true
            } else if character == "[" && !current.isEmpty {
                inBrackets = true
            } else if character.isLetter || character.isNumber || character == "_" || character == "-"
                        || character == "." || character == "*" {
                current.append(character)
            } else {
                finish()
            }
        }
        finish()
        return paths.filter { $0.first?.isLetter == true }
    }
}
