/// `# mobileci-ignore MCI001` comments.
///
/// - `# mobileci-ignore MCI001, MCI012` silences those rules on its own line and on the next one,
///   so it can sit at the end of the line or on the line above.
/// - `# mobileci-ignore-file MCI012` silences the rules in the whole file.
///
/// Rules are named by identifier or name; a comment without any is ignored, so nothing is
/// silenced by accident.
struct Suppressions {
    private var byLine: [Int: Set<RuleID>] = [:]
    private var wholeFile: Set<RuleID> = []

    init(text: String) {
        var lineNumber = 0
        for line in text.split(separator: "\n", omittingEmptySubsequences: false) {
            lineNumber += 1
            guard let directive = Suppressions.directive(in: line) else { continue }
            if directive.wholeFile {
                wholeFile.formUnion(directive.rules)
            } else {
                byLine[lineNumber, default: []].formUnion(directive.rules)
                byLine[lineNumber + 1, default: []].formUnion(directive.rules)
            }
        }
    }

    func isSuppressed(_ finding: Finding) -> Bool {
        wholeFile.contains(finding.rule) || byLine[finding.location.line]?.contains(finding.rule) == true
    }

    private static let marker = "mobileci-ignore"

    private static func directive(in line: Substring) -> (wholeFile: Bool, rules: Set<RuleID>)? {
        // A `#` can also appear inside a quoted value before the comment; try each one.
        for hash in line.indices where line[hash] == "#" {
            if let directive = directive(after: line[line.index(after: hash)...]) { return directive }
        }
        return nil
    }

    private static func directive(after hash: Substring) -> (wholeFile: Bool, rules: Set<RuleID>)? {
        var comment = hash.drop { $0 == " " || $0 == "\t" }
        guard comment.hasPrefix(marker) else { return nil }
        comment = comment.dropFirst(marker.count)
        var wholeFile = false
        if comment.hasPrefix("-file") {
            wholeFile = true
            comment = comment.dropFirst("-file".count)
        }
        guard comment.first == " " || comment.first == ":" || comment.first == "\t" else { return nil }
        let words = comment.split(whereSeparator: { $0 == " " || $0 == "," || $0 == ":" || $0 == "\t" || $0 == "\r" })
        let rules = Set(words.compactMap { RuleID(identifier: String($0)) })
        return rules.isEmpty ? nil : (wholeFile, rules)
    }
}
