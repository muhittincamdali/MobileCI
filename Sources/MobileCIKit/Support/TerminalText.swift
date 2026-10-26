extension String {
    /// The string with control and bidirectional formatting characters replaced by `?`.
    ///
    /// File names and values read from a repository are printed in terminals and CI logs. A
    /// carriage return, an ANSI escape sequence or a right-to-left override in such a value could
    /// otherwise rewrite or reorder what the reader sees.
    public var sanitizedForTerminal: String {
        var result = String.UnicodeScalarView()
        for scalar in unicodeScalars {
            result.append(Self.isUnsafeForTerminal(scalar) ? "?" : scalar)
        }
        return String(result)
    }

    /// The string cut to `limit` characters, with `…` at the end when it was cut.
    func truncated(to limit: Int) -> String {
        guard count > limit else { return self }
        return String(prefix(limit)) + "…"
    }

    private static func isUnsafeForTerminal(_ scalar: Unicode.Scalar) -> Bool {
        switch scalar.value {
        case 0x00...0x1F, 0x7F...0x9F:
            return true
        case 0x061C, 0x200E, 0x200F, 0x202A...0x202E, 0x2066...0x2069:
            return true
        default:
            return false
        }
    }
}
