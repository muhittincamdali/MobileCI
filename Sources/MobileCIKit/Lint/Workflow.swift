import Foundation

/// A GitHub Actions workflow read into the parts the rules look at.
struct Workflow {
    let root: YAMLValue
    let triggers: Set<String>
    let jobs: [Job]
    // Looking a key up scans the mapping, and the rules ask for these for every job or step,
    // so they are read once here.
    let hasPermissions: Bool
    let hasConcurrency: Bool
    let env: YAMLValue?
    let defaultShell: String?

    /// `nil` when the document is not a mapping with a `jobs` mapping.
    init?(root: YAMLValue) {
        guard root.isMapping, let jobs = root["jobs"], jobs.isMapping else { return nil }
        self.root = root
        self.triggers = Workflow.triggers(of: root["on"])
        self.jobs = jobs.members.map { Job(id: $0.key, idLocation: $0.keyLocation, node: $0.value) }
        self.hasPermissions = root["permissions"] != nil
        self.hasConcurrency = root["concurrency"] != nil
        self.env = root["env"]
        self.defaultShell = root["defaults"]?["run"]?["shell"]?.string
    }

    private static func triggers(of node: YAMLValue?) -> Set<String> {
        switch node {
        case .scalar(let name, _)?:
            return [name]
        case .sequence(let items, _)?:
            return Set(items.compactMap(\.string))
        case .mapping(let members, _)?:
            return Set(members.map(\.key))
        case nil:
            return []
        }
    }
}

/// One entry under `jobs:`.
struct Job {
    let id: String
    let idLocation: SourceLocation
    let node: YAMLValue
    /// The runner labels with their locations, each label and location once. A
    /// `${{ matrix.<key> }}` label is replaced by the values listed for that key under
    /// `strategy.matrix` (including `include` entries). Read once here: the rules ask for every
    /// macOS job, and a label repeated through an alias would otherwise expand the matrix again
    /// for every repeat.
    let runnerLabels: [RunnerLabel]

    init(id: String, idLocation: SourceLocation, node: YAMLValue) {
        self.id = id
        self.idLocation = idLocation
        self.node = node
        self.runnerLabels = Job.runnerLabels(of: node)
    }

    /// `uses:` at job level: a call to a reusable workflow, which has no steps of its own.
    var reusableWorkflow: YAMLValue? { node["uses"] }
    var steps: [Step] { (node["steps"]?.items ?? []).map(Step.init) }
    var env: YAMLValue? { node["env"] }
    var defaultShell: String? { node["defaults"]?["run"]?["shell"]?.string }

    /// Whether any runner label names a macOS runner (`macos-26`, `macos-latest-xlarge`, or the
    /// `macOS` label of a self-hosted runner).
    var runsOnMacOS: Bool {
        runnerLabels.contains { $0.label.lowercased().hasPrefix("macos") }
    }

    private static func runnerLabels(of node: YAMLValue) -> [RunnerLabel] {
        guard let runsOn = node["runs-on"] else { return [] }
        let written: [YAMLValue]
        switch runsOn {
        case .scalar:
            written = [runsOn]
        case .sequence(let items, _):
            written = items
        case .mapping:
            written = runsOn["labels"].map { $0.items.isEmpty ? [$0] : $0.items } ?? []
        }
        let keys = Set(written.compactMap { $0.string.flatMap(matrixKey(in:)) })
        let values = keys.isEmpty ? [:] : matrixValues(for: keys, in: node["strategy"]?["matrix"])
        var labels: [RunnerLabel] = []
        var seen = Set<RunnerLabel>()
        var expandedKeys = Set<String>()
        func add(_ label: RunnerLabel) {
            if seen.insert(label).inserted { labels.append(label) }
        }
        for value in written {
            guard let text = value.string else { continue }
            guard let key = matrixKey(in: text) else {
                add(RunnerLabel(label: text, location: value.location))
                continue
            }
            if expandedKeys.insert(key).inserted { values[key]?.forEach(add) }
        }
        return labels
    }

    /// The values of each of `keys` in one pass over the matrix: those listed under the key,
    /// then those set by `include` entries.
    private static func matrixValues(for keys: Set<String>, in matrix: YAMLValue?) -> [String: [RunnerLabel]] {
        guard let matrix else { return [:] }
        var listed: [String: [RunnerLabel]] = [:]
        var included: [String: [RunnerLabel]] = [:]
        for member in matrix.members where keys.contains(member.key) {
            for item in member.value.items {
                if let text = item.string {
                    listed[member.key, default: []].append(RunnerLabel(label: text, location: item.location))
                }
            }
        }
        for entry in matrix["include"]?.items ?? [] {
            for member in entry.members where keys.contains(member.key) {
                if let text = member.value.string {
                    included[member.key, default: []].append(RunnerLabel(label: text, location: member.value.location))
                }
            }
        }
        return listed.merging(included) { $0 + $1 }
    }

    /// `os` for `${{ matrix.os }}`; `nil` for any other text.
    static func matrixKey(in label: String) -> String? {
        let trimmed = label.trimmingCharacters(in: .whitespaces)
        guard trimmed.hasPrefix("${{"), trimmed.hasSuffix("}}") else { return nil }
        let inner = trimmed.dropFirst(3).dropLast(2).trimmingCharacters(in: .whitespaces)
        guard inner.hasPrefix("matrix.") else { return nil }
        let key = String(inner.dropFirst("matrix.".count))
        let allowed = CharacterSet.alphanumerics.union(CharacterSet(charactersIn: "_-"))
        guard !key.isEmpty, key.unicodeScalars.allSatisfy(allowed.contains) else { return nil }
        return key
    }
}

/// A runner label and where it is written.
struct RunnerLabel: Hashable {
    let label: String
    let location: SourceLocation
}

/// One entry under `steps:`.
struct Step {
    let node: YAMLValue

    var uses: YAMLValue? { node["uses"] }
    var run: YAMLValue? { node["run"] }
    var with: YAMLValue? { node["with"] }
    var env: YAMLValue? { node["env"] }
    var shell: String? { node["shell"]?.string }

    /// The action this step uses without its ref, lowercased: `actions/checkout`.
    var actionName: String? {
        guard let reference = uses?.string, !reference.hasPrefix("./"), !reference.hasPrefix("docker://") else {
            return nil
        }
        let name = reference.split(separator: "@", maxSplits: 1).first.map(String.init) ?? reference
        return name.lowercased()
    }

    func input(_ name: String) -> String? {
        with?[name]?.string
    }
}
