/// The untrusted property behind each `env` name in one scope (workflow, job or step). A scope
/// keeps only the names it sets and refers to the scope around it, so building one costs its own
/// members however many names the outer scopes hold: a workflow with W names over S steps is
/// W + S work, not W × S.
final class EnvironmentTaint {
    private let outer: EnvironmentTaint?
    /// Lowercased names this scope sets, untrusted or not; each one hides the outer value.
    private var defined: Set<String> = []
    /// Lowercased name to the untrusted property its value is set from, for this scope's names.
    private var sources: [String: String] = [:]
    /// The start of the untrusted names visible in this scope, in the order GitHub lists them:
    /// this scope's own in file order, then the outer ones it does not hide. It holds this
    /// scope's names at first and grows only as far as a `toJSON(env)` lookup reads.
    private var visible: [(name: String, source: String)] = []
    /// How many of the outer scope's visible names `visible` has taken in or skipped.
    private var outerRead = 0

    /// `scope`'s `env:` over `outer`. A name the scope sets hides the outer value, untrusted or
    /// not. With `readsOuter`, a value that reads `env` (`B: ${{ env.A }}`) is evaluated against
    /// `outer`, as GitHub evaluates it.
    init(scope: YAMLValue?, over outer: EnvironmentTaint?, readsOuter: Bool) {
        self.outer = outer
        for member in scope?.members ?? [] {
            let name = member.key.lowercased()
            // GitHub keeps one value per name; the first one in the file is the one checked.
            guard defined.insert(name).inserted else { continue }
            guard let source = Self.untrustedSource(in: member.value, outer: readsOuter ? outer : nil) else { continue }
            visible.append((name, source))
            sources[name] = source
        }
    }

    /// The untrusted property that `path` (`env.NAME`, or the whole `env` context) is set from.
    func untrustedSource(of path: String) -> String? {
        let segments = path.lowercased().split(separator: ".", omittingEmptySubsequences: false)
        guard segments.first == "env" else { return nil }
        guard segments.count > 1 else { return visibleName(at: 0)?.source }
        return source(of: String(segments[1]))
    }

    private func source(of name: String) -> String? {
        if defined.contains(name) { return sources[name] }
        return outer?.source(of: name)
    }

    /// The `index`th untrusted name visible in this scope. Every outer name skipped on the way is
    /// one that this scope sets, and what is read is kept, so a scope reads each outer name once.
    private func visibleName(at index: Int) -> (name: String, source: String)? {
        while visible.count <= index {
            guard let entry = outer?.visibleName(at: outerRead) else { return nil }
            outerRead += 1
            if !defined.contains(entry.name) { visible.append(entry) }
        }
        return visible[index]
    }

    private static func untrustedSource(in value: YAMLValue, outer: EnvironmentTaint?) -> String? {
        guard let text = value.string else { return nil }
        for occurrence in Expressions.occurrences(in: text) {
            for path in Expressions.propertyPaths(in: occurrence.body) {
                if UntrustedInput.isUntrusted(path) { return path }
                if let source = outer?.untrustedSource(of: path) { return source }
            }
        }
        return nil
    }
}
