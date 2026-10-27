/// An action at a release, pinned to the release's commit.
public struct PinnedAction: Sendable, Equatable {
    public let name: String
    public let tag: String
    public let commit: String

    /// `uses: owner/repo@<sha> # <tag>`.
    public var reference: String { "\(name)@\(commit) # \(tag)" }

    /// The actions generated workflows use. Each commit is the one the release tag points to
    /// (read with `gh api repos/<owner>/<repo>/commits/<tag>`); Dependabot's
    /// `github-actions` ecosystem updates them in a generated workflow like any other.
    public static let checkout = PinnedAction(name: "actions/checkout", tag: "v7.0.1",
                                              commit: "3d3c42e5aac5ba805825da76410c181273ba90b1")
    public static let cache = PinnedAction(name: "actions/cache", tag: "v6.1.0",
                                           commit: "55cc8345863c7cc4c66a329aec7e433d2d1c52a9")
    public static let uploadArtifact = PinnedAction(name: "actions/upload-artifact", tag: "v7.0.2",
                                                    commit: "cf430e030ddbb5b0abf93d22962f4752f3646cd9")
    public static let setupNode = PinnedAction(name: "actions/setup-node", tag: "v7.1.0",
                                               commit: "949feb2413d6458794dcd2491c4babbbce0c15c1")
    public static let setupJava = PinnedAction(name: "actions/setup-java", tag: "v6.1.0",
                                               commit: "b843ebf9b913146b38da2eaa7aeddf76074ae1ad")
    public static let flutter = PinnedAction(name: "subosito/flutter-action", tag: "v2.23.0",
                                             commit: "1a449444c387b1966244ae4d4f8c696479add0b2")

    public static let all: [PinnedAction] = [checkout, cache, uploadArtifact, setupNode, setupJava, flutter]
}
