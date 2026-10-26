import Foundation

/// A folder under the system temporary directory that is removed when the value is released.
final class TemporaryFolder {
    let url: URL

    init() throws {
        url = FileManager.default.temporaryDirectory
            .appendingPathComponent("MobileCIKitTests-\(UUID().uuidString)", isDirectory: true)
        try FileManager.default.createDirectory(at: url, withIntermediateDirectories: true)
    }

    deinit {
        try? FileManager.default.removeItem(at: url)
    }

    /// Writes `contents` to `path` (relative), creating the folders on the way.
    @discardableResult
    func write(_ path: String, _ contents: String = "") throws -> URL {
        let file = url.appendingPathComponent(path)
        try FileManager.default.createDirectory(at: file.deletingLastPathComponent(), withIntermediateDirectories: true)
        try Data(contents.utf8).write(to: file)
        return file
    }

    @discardableResult
    func folder(_ path: String) throws -> URL {
        let folder = url.appendingPathComponent(path, isDirectory: true)
        try FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true)
        return folder
    }

    func read(_ path: String) throws -> String {
        try String(contentsOf: url.appendingPathComponent(path), encoding: .utf8)
    }
}

/// Minimal project files, as Xcode, Flutter and npm write them.
enum Fixture {
    static func scheme(withTests: Bool) -> String {
        let testables = withTests ? """
              <Testables>
                 <TestableReference skipped = "NO">
                    <BuildableReference BuildableName = "AppTests.xctest" BlueprintName = "AppTests"/>
                 </TestableReference>
              </Testables>
        """ : "<Testables></Testables>"
        return """
        <?xml version="1.0" encoding="UTF-8"?>
        <Scheme LastUpgradeVersion = "2600" version = "1.7">
           <TestAction buildConfiguration = "Debug">
        \(testables)
           </TestAction>
        </Scheme>
        """
    }

    static func projectFile(sdk: String = "iphoneos", marketing: String = "1.0", build: String = "1", remotePackage: Bool = false) -> String {
        """
        // !$*UTF8*$!
        {
        \tobjects = {
        \(remotePackage ? "\t\tA1 /* XCRemoteSwiftPackageReference \"Yams\" */ = {isa = XCRemoteSwiftPackageReference;};" : "")
        \t\tB1 /* Debug */ = {
        \t\t\tbuildSettings = {
        \t\t\t\tCURRENT_PROJECT_VERSION = \(build);
        \t\t\t\tMARKETING_VERSION = \(marketing);
        \t\t\t\tSDKROOT = \(sdk);
        \t\t\t};
        \t\t};
        \t\tB2 /* Release */ = {
        \t\t\tbuildSettings = {
        \t\t\t\tCURRENT_PROJECT_VERSION = \(build);
        \t\t\t\tMARKETING_VERSION = \(marketing);
        \t\t\t\tSDKROOT = \(sdk);
        \t\t\t};
        \t\t};
        \t};
        }
        """
    }

    /// An Xcode project `App.xcodeproj` in `directory` with the given shared schemes.
    static func xcodeProject(in folder: TemporaryFolder, directory: String = ".", name: String = "App",
                             schemes: [(String, Bool)] = [("App", true)], sdk: String = "iphoneos") throws {
        let base = directory == "." ? "" : directory + "/"
        try folder.write("\(base)\(name).xcodeproj/project.pbxproj", projectFile(sdk: sdk))
        for (scheme, tests) in schemes {
            try folder.write("\(base)\(name).xcodeproj/xcshareddata/xcschemes/\(scheme).xcscheme", Fixture.scheme(withTests: tests))
        }
    }

    static let flutterPubspec = """
    name: shop
    version: 1.2.3+45
    environment:
      sdk: ^3.13.0
      flutter: 3.47.8
    dependencies:
      flutter:
        sdk: flutter
    """
}
