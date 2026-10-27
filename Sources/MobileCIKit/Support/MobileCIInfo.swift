/// Version and links of the MobileCI tool.
public enum MobileCIInfo {
    /// The tool version written into generated workflows and printed by `mobileci --version`.
    public static let version = "2.0.0"

    /// The source repository.
    public static let repositoryURL = "https://github.com/muhittincamdali/MobileCI"

    /// The documentation site built from the DocC catalog.
    public static let documentationURL = "https://muhittincamdali.github.io/MobileCI/documentation/mobilecikit"

    /// The page that describes every lint rule.
    public static let rulesURL = documentationURL + "/lintrules"
}
