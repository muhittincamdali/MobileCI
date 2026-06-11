import Foundation

/// Lightweight CI environment detection for MobileCIKit commands.
public struct CIEnvironment {
    public enum Provider: String {
        case githubActions = "GitHub Actions"
        case bitrise = "Bitrise"
        case circleCI = "CircleCI"
        case jenkins = "Jenkins"
        case travisCI = "Travis CI"
        case azurePipelines = "Azure Pipelines"
        case gitlabCI = "GitLab CI"
        case local = "Local"
    }

    public let provider: Provider

    public var rawValue: String {
        provider.rawValue
    }

    public static func detect() -> CIEnvironment {
        detect(environment: ProcessInfo.processInfo.environment)
    }

    static func detect(environment: [String: String]) -> CIEnvironment {
        if environment["GITHUB_ACTIONS"] == "true" { return CIEnvironment(provider: .githubActions) }
        if environment["BITRISE_IO"] == "true" { return CIEnvironment(provider: .bitrise) }
        if environment["CIRCLECI"] == "true" { return CIEnvironment(provider: .circleCI) }
        if environment["JENKINS_HOME"] != nil || environment["JENKINS_URL"] != nil {
            return CIEnvironment(provider: .jenkins)
        }
        if environment["TRAVIS"] == "true" { return CIEnvironment(provider: .travisCI) }
        if environment["TF_BUILD"] == "True" || environment["TF_BUILD"] == "true" {
            return CIEnvironment(provider: .azurePipelines)
        }
        if environment["GITLAB_CI"] == "true" { return CIEnvironment(provider: .gitlabCI) }
        return CIEnvironment(provider: .local)
    }
}
