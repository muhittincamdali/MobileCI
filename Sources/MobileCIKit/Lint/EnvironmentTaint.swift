/// The untrusted property behind each `env` name in one scope, with the outer scopes laid
/// under it. It is built once per scope from the outside in (workflow, then job, then step),
/// so a value that reads `env` again costs one lookup in the outer scopes, not a new search
/// of them for every member that asks.
struct EnvironmentTaint {
    /// Untrusted names in the order GitHub lists them: the innermost scope first.
    private var ordered: [(name: String, source: String)] = []
    /// Lowercased name to the untrusted property its effective value is set from.
    private var sources: [String: String] = [:]

    static let empty = EnvironmentTaint()

    private init() {}

    /// `scope`'s `env:` over `outer`. A name the scope sets hides the outer value, untrusted or
    /// not. With `readsOuter`, a value that reads `env` (`B: ${{ env.A }}`) is evaluated against
    /// `outer`, as GitHub evaluates it.
    init(scope: YAMLValue?, over outer: EnvironmentTaint, readsOuter: Bool) {
        var defined: Set<String> = []
        for member in scope?.members ?? [] {
            let name = member.key.lowercased()
            // GitHub keeps one value per name; the first one in the file is the one checked.
            guard defined.insert(name).inserted else { continue }
            guard let source = Self.untrustedSource(in: member.value, outer: readsOuter ? outer : .empty) else { continue }
            ordered.append((name, source))
            sources[name] = source
        }
        for entry in outer.ordered where !defined.contains(entry.name) {
            ordered.append(entry)
            sources[entry.name] = entry.source
        }
    }

    /// The untrusted property that `path` (`env.NAME`, or the whole `env` context) is set from.
    func untrustedSource(of path: String) -> String? {
        let segments = path.lowercased().split(separator: ".", omittingEmptySubsequences: false)
        guard segments.first == "env" else { return nil }
        guard segments.count > 1 else { return ordered.first?.source }
        return sources[String(segments[1])]
    }

    private static func untrustedSource(in value: YAMLValue, outer: EnvironmentTaint) -> String? {
        guard let text = value.string else { return nil }
        for occurrence in Expressions.occurrences(in: text) {
            for path in Expressions.propertyPaths(in: occurrence.body) {
                if UntrustedInput.isUntrusted(path) { return path }
                if let source = outer.untrustedSource(of: path) { return source }
            }
        }
        return nil
    }
}
