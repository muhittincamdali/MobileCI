import Foundation
@testable import MobileCIKit
import Testing

struct TextFileTests {
    @Test func readsUTF8() throws {
        let folder = try TemporaryFolder()
        let url = try folder.write("a.yml", "name: ş\n")
        #expect(try TextFile.read(url) == "name: ş\n")
    }

    @Test func refusesLargeBinaryMissingAndFolders() throws {
        let folder = try TemporaryFolder()
        let large = try folder.write("large.yml", String(repeating: "a", count: 2_049))
        #expect(throws: TextFileError.tooLarge(path: large.path, limit: 2_048)) { try TextFile.read(large, limit: 2_048) }
        let binary = folder.url.appendingPathComponent("binary.yml")
        try Data([0xFF, 0xFE, 0x00, 0xD8]).write(to: binary)
        #expect(throws: TextFileError.notUTF8(path: binary.path)) { try TextFile.read(binary) }
        let missing = folder.url.appendingPathComponent("missing.yml")
        #expect(throws: TextFileError.missing(path: missing.path)) { try TextFile.read(missing) }
        let directory = try folder.folder("dir.yml")
        #expect(throws: TextFileError.unreadable(path: directory.path)) { try TextFile.read(directory) }
    }

    @Test func brokenLinksAreMissingAndDevicesUnreadable() throws {
        let folder = try TemporaryFolder()
        let link = folder.url.appendingPathComponent("broken.yml")
        try FileManager.default.createSymbolicLink(atPath: link.path, withDestinationPath: "nowhere.yml")
        #expect(throws: TextFileError.missing(path: link.path)) { try TextFile.read(link) }
        #expect(throws: TextFileError.unreadable(path: "/dev/zero")) { try TextFile.read(URL(fileURLWithPath: "/dev/zero")) }
    }

    /// Opening a FIFO for reading would block until a writer appears; it is opened without
    /// waiting and refused once its type is known.
    @Test func refusesFIFOs() throws {
        let folder = try TemporaryFolder()
        let fifo = folder.url.appendingPathComponent("pipe.yml")
        #expect(mkfifo(fifo.path, 0o600) == 0)
        #expect(throws: TextFileError.unreadable(path: fifo.path)) { try TextFile.read(fifo) }
        let findings = WorkflowLinter().lint(fileAt: fifo, displayPath: "pipe.yml")
        #expect(findings.map(\.rule) == [.invalidWorkflow])
    }

    @Test func readsThroughSymbolicLinksToFiles() throws {
        let folder = try TemporaryFolder()
        let target = try folder.write("real.yml", "x")
        let link = folder.url.appendingPathComponent("link.yml")
        try FileManager.default.createSymbolicLink(at: link, withDestinationURL: target)
        #expect(try TextFile.read(link) == "x")
    }

    @Test func workflowFilesForAFolder() throws {
        let folder = try TemporaryFolder()
        try folder.write(".github/workflows/b.yml", "")
        try folder.write(".github/workflows/a.yaml", "")
        try folder.write(".github/workflows/notes.md", "")
        let files = WorkflowLinter.workflowFiles(for: [folder.url, folder.url.appendingPathComponent(".github/workflows/b.yml")])
        #expect(files.map(\.lastPathComponent) == ["a.yaml", "b.yml"])
    }

    @Test func directoryListingStopsAtTheLimit() throws {
        let folder = try TemporaryFolder()
        for index in 0..<5 { try folder.write("f\(index)") }
        let partial = DirectoryListing.entries(of: folder.url, limit: 3)
        #expect(partial.urls.count == 3 && !partial.complete)
        let full = DirectoryListing.entries(of: folder.url, limit: 5)
        #expect(full.urls.count == 5 && full.complete)
        #expect(DirectoryListing.entries(of: folder.url.appendingPathComponent("missing"), limit: 5).urls.isEmpty)
    }

    @Test func terminalSanitising() {
        #expect("ok\u{1B}[31m\r\n\u{7F}\u{9B}\u{202E}\u{2066}".sanitizedForTerminal == "ok?[31m?????\u{3F}")
        #expect("Şifre 漢字 🔑".sanitizedForTerminal == "Şifre 漢字 🔑")
    }
}
