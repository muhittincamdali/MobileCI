import Foundation

/// Finds the iOS, Swift package, Flutter and React Native projects in a repository.
///
/// The search looks at the root and at folders up to ``maximumDepth`` levels below it. It does
/// not follow symbolic links, skips dependency and build folders (`node_modules`, `Pods`,
/// `.build`, `build`, `DerivedData`…) and stops after ``maximumEntries`` directory entries, so a
/// large or cyclic tree cannot keep it running.
public struct ProjectDetector: Sendable {
    public static let maximumDepth = 3
    public static let maximumEntries = 20_000

    static let skippedFolders: Set<String> = [
        "node_modules", "Pods", "Carthage", "build", "DerivedData", "vendor", "fastlane",
        "SourcePackages", "Packages", "dist", "coverage"
    ]

    public init() {}

    public func detect(in root: URL) -> DetectionReport {
        var projects: [DetectedProject] = []
        var notes: [DetectionNote] = []
        var budget = Self.maximumEntries
        var queue: [(url: URL, relative: String, depth: Int)] = [(root, ".", 0)]
        while !queue.isEmpty {
            let (folder, relative, depth) = queue.removeFirst()
            guard let entries = Self.entries(of: folder, budget: &budget) else {
                notes.append(DetectionNote(directory: relative, severity: .warning,
                                           message: "Stopped after \(Self.maximumEntries) entries; pass a project folder to look deeper."))
                break
            }
            let found = Self.projects(in: folder, relative: relative, entries: entries)
            projects += found.projects
            notes += found.notes
            // A Flutter or React Native project owns its ios/ and android/ folders.
            guard depth < Self.maximumDepth, !found.ownsSubfolders else { continue }
            for entry in entries where entry.isFolder && Self.shouldDescend(into: entry.name) {
                let child = relative == "." ? entry.name : relative + "/" + entry.name
                queue.append((folder.appendingPathComponent(entry.name, isDirectory: true), child, depth + 1))
            }
        }
        return DetectionReport(projects: projects, notes: notes)
    }

    struct Entry {
        let name: String
        let isFolder: Bool
    }

    /// The folder's entries, or `nil` when the budget runs out. Symbolic links are listed as
    /// files, so they are never followed.
    private static func entries(of folder: URL, budget: inout Int) -> [Entry]? {
        let keys: [URLResourceKey] = [.isDirectoryKey, .isSymbolicLinkKey]
        let listing = DirectoryListing.entries(of: folder, limit: budget, keys: keys)
        guard listing.complete else { return nil }
        budget -= listing.urls.count
        return listing.urls.map { url in
            let values = try? url.resourceValues(forKeys: Set(keys))
            let isLink = values?.isSymbolicLink ?? false
            return Entry(name: url.lastPathComponent, isFolder: !isLink && (values?.isDirectory ?? false))
        }.sorted { $0.name < $1.name }
    }

    private static func shouldDescend(into name: String) -> Bool {
        guard !name.hasPrefix("."), !skippedFolders.contains(name) else { return false }
        let bundleExtensions = ["xcodeproj", "xcworkspace", "app", "framework", "xcframework", "bundle", "xcassets", "lproj", "docc"]
        return !bundleExtensions.contains((name as NSString).pathExtension)
    }

    private static func projects(in folder: URL, relative: String, entries: [Entry])
        -> (projects: [DetectedProject], notes: [DetectionNote], ownsSubfolders: Bool) {
        let names = Set(entries.map(\.name))
        var notes: [DetectionNote] = []
        func note(_ severity: Severity, _ message: String) {
            notes.append(DetectionNote(directory: relative, severity: severity, message: message))
        }

        if names.contains("pubspec.yaml"), let flutter = ManifestReader.flutter(in: folder, names: names) {
            return ([DetectedProject(directory: relative, kind: .flutter(flutter))], notes, true)
        }
        if names.contains("package.json"), let reactNative = ManifestReader.reactNative(in: folder, names: names, note: note) {
            return ([DetectedProject(directory: relative, kind: .reactNative(reactNative))], notes, true)
        }
        let projectFiles = entries.filter { $0.isFolder && $0.name.hasSuffix(".xcodeproj") }.map(\.name)
        if let projectFile = projectFiles.first {
            if projectFiles.count > 1 {
                note(.note, "Found \(projectFiles.count) Xcode projects; using \(projectFile.sanitizedForTerminal). Pass --project to choose another.")
            }
            let project = XcodeReader.project(projectFile, in: folder, entries: entries, note: note)
            return ([DetectedProject(directory: relative, kind: .xcode(project))], notes, false)
        }
        if names.contains("Package.swift") {
            let package = ManifestReader.swiftPackage(in: folder, names: names)
            return ([DetectedProject(directory: relative, kind: .swiftPackage(package))], notes, false)
        }
        return ([], notes, false)
    }
}
