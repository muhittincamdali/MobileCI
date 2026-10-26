import Foundation

/// Lists a folder's direct entries without reading more than a limit, so a folder with
/// millions of files cannot fill memory before a budget check runs.
enum DirectoryListing {
    /// At most `limit` entries of `folder` (hidden ones included, nothing below them), and
    /// whether that was all of them. An unreadable folder gives no entries.
    static func entries(of folder: URL, limit: Int, keys: [URLResourceKey] = []) -> (urls: [URL], complete: Bool) {
        guard limit > 0 else { return ([], false) }
        guard let enumerator = FileManager.default.enumerator(
            at: folder, includingPropertiesForKeys: keys, options: [.skipsSubdirectoryDescendants]
        ) else { return ([], true) }
        var urls: [URL] = []
        while let url = enumerator.nextObject() as? URL {
            guard urls.count < limit else { return (urls, false) }
            urls.append(url)
        }
        return (urls, true)
    }
}
