import Foundation

/// Why a file could not be read as text.
public enum TextFileError: Error, Equatable, Sendable, CustomStringConvertible {
    case missing(path: String)
    case tooLarge(path: String, limit: Int)
    case notUTF8(path: String)
    case unreadable(path: String)

    public var description: String {
        switch self {
        case .missing(let path):
            return "\(path.sanitizedForTerminal): no such file"
        case .tooLarge(let path, let limit):
            return "\(path.sanitizedForTerminal): larger than \(limit / 1024) KiB, not read"
        case .notUTF8(let path):
            return "\(path.sanitizedForTerminal): not UTF-8 text"
        case .unreadable(let path):
            return "\(path.sanitizedForTerminal): cannot be read"
        }
    }
}

/// Reads text files with an upper size bound, so a huge or endless file (a FIFO, `/dev/zero`)
/// cannot exhaust memory. Symbolic links to files are followed, as `open(2)` does.
public enum TextFile {
    /// Size limit for workflow, manifest and configuration files.
    public static let defaultLimit = 1 << 20

    /// Size limit for Xcode `project.pbxproj` files, which grow with the number of source files.
    public static let projectFileLimit = 32 << 20

    /// Reads at most `limit` bytes; a longer file fails with ``TextFileError/tooLarge(path:limit:)``.
    public static func read(_ url: URL, limit: Int = defaultLimit) throws(TextFileError) -> String {
        let path = url.path
        // The type is checked on the opened descriptor, so the file cannot be swapped for a FIFO
        // or a device between the check and the read. `O_NONBLOCK` keeps the open itself from
        // waiting for a FIFO writer; it has no effect on reading a regular file.
        let descriptor = open(path, O_RDONLY | O_NONBLOCK | O_CLOEXEC)
        guard descriptor >= 0 else {
            throw errno == ENOENT || errno == ENOTDIR ? .missing(path: path) : .unreadable(path: path)
        }
        let handle = FileHandle(fileDescriptor: descriptor, closeOnDealloc: true)
        defer { try? handle.close() }
        var status = stat()
        guard fstat(descriptor, &status) == 0, status.st_mode & mode_t(S_IFMT) == mode_t(S_IFREG) else {
            throw .unreadable(path: path)
        }
        // Reading one byte past the limit detects an oversized file without trusting its
        // reported size, which a file that grows while it is read would make wrong.
        let data: Data
        do {
            data = try handle.read(upToCount: limit + 1) ?? Data()
        } catch {
            throw .unreadable(path: path)
        }
        guard data.count <= limit else { throw .tooLarge(path: path, limit: limit) }
        guard let text = String(data: data, encoding: .utf8) else { throw .notUTF8(path: path) }
        return text
    }
}
