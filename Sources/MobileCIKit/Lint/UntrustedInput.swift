/// Context properties whose text an outside contributor chooses: titles, bodies, branch names,
/// commit messages and author names. The list follows GitHub's guide "Security hardening for
/// GitHub Actions" (understanding the risk of script injections).
enum UntrustedInput {
    static let paths: [[String]] = [
        "github.event.issue.title",
        "github.event.issue.body",
        "github.event.pull_request.title",
        "github.event.pull_request.body",
        "github.event.pull_request.head.ref",
        "github.event.pull_request.head.label",
        "github.event.pull_request.head.repo.default_branch",
        "github.event.comment.body",
        "github.event.review.body",
        "github.event.review_comment.body",
        "github.event.discussion.title",
        "github.event.discussion.body",
        "github.event.pages.*.page_name",
        "github.event.commits.*.message",
        "github.event.commits.*.author.email",
        "github.event.commits.*.author.name",
        "github.event.head_commit.message",
        "github.event.head_commit.author.email",
        "github.event.head_commit.author.name",
        "github.event.workflow_run.head_branch",
        "github.event.workflow_run.head_commit.message",
        "github.event.workflow_run.head_commit.author.email",
        "github.event.workflow_run.head_commit.author.name",
        "github.event.workflow_run.pull_requests.*.head.ref",
        "github.head_ref"
    ].map { $0.split(separator: ".").map(String.init) }

    /// Whether the normalised property `path` is untrusted text or an object that contains some
    /// (`github.event.pull_request`, `github.event`, `github`), as `toJSON(github.event)` would
    /// expand all of it.
    static func isUntrusted(_ path: String) -> Bool {
        let segments = path.lowercased().split(separator: ".").map(String.init)
        guard !segments.isEmpty else { return false }
        return paths.contains { pattern in
            let shared = min(pattern.count, segments.count)
            for index in 0..<shared where !matches(pattern[index], segments[index]) {
                return false
            }
            // Equal, a property below the untrusted one (`….head.ref.length`), or an object
            // that contains it.
            return true
        }
    }

    private static func matches(_ pattern: String, _ segment: String) -> Bool {
        pattern == "*" || segment == "*" || pattern == segment
    }
}
