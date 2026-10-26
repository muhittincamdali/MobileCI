import Foundation

extension Rules {
    // MARK: MCI008, MCI011, MCI015

    static func checkScripts(_ context: inout RuleContext) {
        for job in context.workflow.jobs {
            for step in job.steps {
                // GitHub takes `env.NAME` from the step, then the job, then the workflow.
                let environment = [step.env, job.env, context.workflow.env]
                if let run = step.run, let script = run.string {
                    checkExpressions(in: script, at: run.location, isScript: true, environment: environment, &context)
                    checkPipes(in: script, at: run.location, shell: shell(of: step, in: job, context.workflow), &context)
                }
                if step.actionName == "actions/github-script", let script = step.with?["script"], let text = script.string {
                    checkExpressions(in: text, at: script.location, isScript: false, environment: environment, &context)
                }
            }
        }
    }

    private static func checkExpressions(in script: String, at start: SourceLocation, isScript: Bool,
                                         environment: [YAMLValue?], _ context: inout RuleContext) {
        for occurrence in Expressions.occurrences(in: script) {
            let location = SourceLocation(line: start.line + occurrence.lineOffset, column: start.column)
            for path in Expressions.propertyPaths(in: occurrence.body) {
                if UntrustedInput.isUntrusted(path) {
                    let shown = quoted(path, allowed: propertyPathCharacters, fallback: "an event property")
                    context.report(.untrustedInputInScript, at: location,
                                   "The script expands \(shown), text that anyone opening a pull request or issue can choose; pass it through `env:` and quote the variable.")
                } else if let source = untrustedSource(of: path, in: environment) {
                    let shown = quoted(path, allowed: propertyPathCharacters, fallback: "an environment variable")
                    let origin = quoted(source, allowed: propertyPathCharacters, fallback: "an event property")
                    context.report(.untrustedInputInScript, at: location,
                                   "The script expands \(shown), which is set from \(origin), text that anyone opening a pull request or issue can choose; read the variable when the script runs (a quoted shell variable, or `process.env` in github-script) instead.")
                } else if isScript, path.lowercased().hasPrefix("secrets.") {
                    let shown = quoted(path, allowed: labelCharacters, fallback: "a secret")
                    context.report(.secretInScript, at: location,
                                   "The script expands \(shown) into its source text; map it to a step `env:` variable instead.")
                }
            }
        }
    }

    /// The untrusted property that the `env.NAME` path (or the whole `env` context) is set from,
    /// in the first of `scopes` (step, job, workflow `env:`) that defines the name.
    static func untrustedSource(of path: String, in scopes: [YAMLValue?]) -> String? {
        let segments = path.lowercased().split(separator: ".", omittingEmptySubsequences: false)
        guard segments.first == "env" else { return nil }
        guard segments.count > 1 else {
            return scopes.lazy.flatMap { $0?.members ?? [] }.compactMap { untrustedSource(in: $0.value) }.first
        }
        let name = String(segments[1])
        for scope in scopes {
            guard let member = scope?.members.first(where: { $0.key.lowercased() == name }) else { continue }
            return untrustedSource(in: member.value)
        }
        return nil
    }

    private static func untrustedSource(in value: YAMLValue) -> String? {
        guard let text = value.string else { return nil }
        for occurrence in Expressions.occurrences(in: text) {
            if let path = Expressions.propertyPaths(in: occurrence.body).first(where: UntrustedInput.isUntrusted) {
                return path
            }
        }
        return nil
    }

    /// The shell GitHub uses for a step: the step's `shell`, then the job's and the workflow's
    /// `defaults.run.shell`.
    private static func shell(of step: Step, in job: Job, _ workflow: Workflow) -> String? {
        step.shell ?? job.defaultShell ?? workflow.defaultShell
    }

    /// Tools whose exit status a formatter pipe (`| xcbeautify`, `| xcpretty`, `| tee`) hides.
    static let buildTools = ["xcodebuild", "fastlane", "gradlew", "gradle", "flutter", "swift"]

    private static func checkPipes(in script: String, at start: SourceLocation, shell: String?, _ context: inout RuleContext) {
        // With `shell: bash` GitHub runs `bash --noprofile --norc -eo pipefail {0}`; with no
        // shell it runs `bash -e {0}`, where a pipeline's status is that of its last command.
        guard shell?.trimmingCharacters(in: .whitespaces) != "bash", !script.contains("pipefail") else { return }
        var lineOffset = 0
        for logicalLine in logicalLines(of: script) {
            defer { lineOffset += logicalLine.lineCount }
            guard let tool = pipedTool(in: logicalLine.text) else { continue }
            context.report(.pipeHidesBuildFailure, at: SourceLocation(line: start.line + lineOffset, column: start.column),
                           "`\(tool)` is piped into another command without `set -o pipefail`, so the step passes when \(tool) fails.")
        }
    }

    /// The first build tool in `line` that is followed by a `|` pipe (not `||`).
    static func pipedTool(in line: String) -> String? {
        let code = line.split(separator: "#", maxSplits: 1, omittingEmptySubsequences: false).first.map(String.init) ?? line
        // `|` and `&` end a word too, so `xcodebuild|xcpretty` and `cd ios&&xcodebuild` are read
        // the way the shell reads them.
        let separators: Set<Character> = [" ", "\t", ";", "(", "|", "&"]
        let words = code.split(whereSeparator: separators.contains)
        guard let toolWord = words.first(where: { word in
            let name = word.split(separator: "/").last.map(String.init) ?? String(word)
            return buildTools.contains(name)
        }) else { return nil }
        // `split` returns slices of `code`, so the word's end index is a position in `code`.
        let rest = code[toolWord.endIndex...]
        var previous: Character = " "
        for (index, character) in zip(rest.indices, rest) {
            let next = rest.index(after: index) < rest.endIndex ? rest[rest.index(after: index)] : " "
            if character == "|", previous != "|", next != "|" {
                return toolWord.split(separator: "/").last.map(String.init)
            }
            previous = character
        }
        return nil
    }

    /// Script lines with backslash continuations joined, and how many source lines each spans.
    static func logicalLines(of script: String) -> [(text: String, lineCount: Int)] {
        var result: [(String, Int)] = []
        var buffer = ""
        var count = 0
        for line in script.split(separator: "\n", omittingEmptySubsequences: false) {
            count += 1
            if line.hasSuffix("\\") {
                buffer += line.dropLast() + " "
                continue
            }
            result.append((buffer + line, count))
            buffer = ""
            count = 0
        }
        if !buffer.isEmpty { result.append((buffer, count)) }
        return result
    }
}
