import Foundation

extension Rules {
    // MARK: MCI006, MCI007

    static func checkPermissions(_ context: inout RuleContext) {
        let workflow = context.workflow
        if let permissions = workflow.root["permissions"] {
            checkWriteAll(permissions, owner: "The workflow", &context)
        }
        for job in workflow.jobs {
            if let permissions = job.node["permissions"] {
                checkWriteAll(permissions, owner: "Job \(jobName(job))", &context)
            } else if !workflow.hasPermissions {
                context.report(.defaultTokenPermissions, at: job.idLocation,
                               "Job \(jobName(job)) gets the repository's default GITHUB_TOKEN permissions, which can include write access; set `permissions:` on the workflow or the job.")
            }
        }
    }

    private static func checkWriteAll(_ permissions: YAMLValue, owner: String, _ context: inout RuleContext) {
        guard permissions.string?.trimmingCharacters(in: .whitespaces).lowercased() == "write-all" else { return }
        context.report(.writeAllPermissions, at: permissions.location,
                       "\(owner) grants write-all to GITHUB_TOKEN; list only the scopes it needs.")
    }

    // MARK: MCI009

    static func checkPullRequestTarget(_ context: inout RuleContext) {
        guard context.workflow.triggers.contains("pull_request_target") else { return }
        for job in context.workflow.jobs {
            for step in job.steps where step.actionName == "actions/checkout" {
                let inputs = [step.with?["ref"], step.with?["repository"]].compactMap { $0 }
                guard let input = inputs.first(where: { checksOutPullRequest($0.string ?? "") }) else { continue }
                context.report(.pullRequestTargetCheckout, at: input.location,
                               "This pull_request_target job checks out the pull request's code; it runs with this repository's secrets and a write token.")
            }
        }
    }

    private static func checksOutPullRequest(_ value: String) -> Bool {
        let lowered = value.lowercased()
        if lowered.contains("refs/pull/") || lowered.contains("merge_commit_sha") { return true }
        return Expressions.occurrences(in: value).contains { occurrence in
            Expressions.propertyPaths(in: occurrence.body).map { $0.lowercased() }.contains { path in
                path.hasPrefix("github.event.pull_request.head") || path == "github.head_ref"
            }
        }
    }

    // MARK: MCI010

    static func checkContinueOnError(_ context: inout RuleContext) {
        for job in context.workflow.jobs {
            if let value = job.node["continue-on-error"], isTrue(value) {
                context.report(.continueOnError, at: value.location,
                               "Job \(jobName(job)) sets continue-on-error: true, so the run is green when this job fails.")
            }
            for step in job.steps {
                if let value = step.node["continue-on-error"], isTrue(value) {
                    context.report(.continueOnError, at: value.location,
                                   "A step in job \(jobName(job)) sets continue-on-error: true, so its failure does not fail the job.")
                }
            }
        }
    }

    private static func isTrue(_ value: YAMLValue) -> Bool {
        value.string?.trimmingCharacters(in: .whitespaces).lowercased() == "true"
    }
}
