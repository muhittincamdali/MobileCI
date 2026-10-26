import Foundation
@testable import MobileCIKit
import Testing

struct DetectorTests {
    func detect(_ folder: TemporaryFolder) -> DetectionReport {
        ProjectDetector().detect(in: folder.url)
    }

    @Test func xcodeProjectWithSharedSchemes() throws {
        let folder = try TemporaryFolder()
        try Fixture.xcodeProject(in: folder, schemes: [("App", true), ("Widgets", false)])
        let report = detect(folder)
        guard case .xcode(let project)? = report.projects.first?.kind else {
            Issue.record("no Xcode project in \(report)")
            return
        }
        #expect(report.projects.first?.directory == ".")
        #expect(project.schemes == [XcodeScheme(name: "App", hasTests: true), XcodeScheme(name: "Widgets", hasTests: false)])
        #expect(project.defaultScheme?.name == "App")
        #expect(project.platform == .iOS)
        #expect(project.workspaceFile == nil)
        #expect(report.notes.isEmpty)
    }

    @Test func missingSharedSchemeIsExplained() throws {
        let folder = try TemporaryFolder()
        try Fixture.xcodeProject(in: folder, schemes: [])
        let report = detect(folder)
        #expect(report.notes.first?.severity == .warning)
        #expect(report.notes.first?.message.contains("Manage Schemes") == true)
        guard case .xcode(let project)? = report.projects.first?.kind else {
            Issue.record("no Xcode project")
            return
        }
        #expect(project.schemes.isEmpty && project.defaultScheme == nil)
    }

    @Test func cocoaPodsWorkspaceAndBundler() throws {
        let folder = try TemporaryFolder()
        try Fixture.xcodeProject(in: folder, directory: "ios", name: "Shop")
        try folder.write("ios/Podfile", "platform :ios, '17.0'\n")
        try folder.write("ios/Gemfile", "gem 'cocoapods'\n")
        guard case .xcode(let project)? = detect(folder).projects.first?.kind else {
            Issue.record("no Xcode project")
            return
        }
        #expect(project.usesCocoaPods && project.usesBundler)
        #expect(project.workspaceFile == "Shop.xcworkspace")
    }

    @Test func macOSProjectAndSwiftPackageReferences() throws {
        let folder = try TemporaryFolder()
        try folder.write("Mac.xcodeproj/project.pbxproj", Fixture.projectFile(sdk: "macosx", remotePackage: true))
        try folder.write("Mac.xcodeproj/xcshareddata/xcschemes/Mac.xcscheme", Fixture.scheme(withTests: false))
        guard case .xcode(let project)? = detect(folder).projects.first?.kind else {
            Issue.record("no Xcode project")
            return
        }
        #expect(project.platform == .macOS)
        #expect(project.usesSwiftPackages)
    }

    @Test func swiftPackageNameIsReadWithoutRunningTheManifest() throws {
        let folder = try TemporaryFolder()
        try folder.write("Package.swift", "// swift-tools-version: 6.2\nimport PackageDescription\nlet package = Package(\n    name: \"Kit\",\n    targets: []\n)\n")
        try folder.folder("Tests")
        #expect(detect(folder).projects == [DetectedProject(directory: ".", kind: .swiftPackage(SwiftPackage(name: "Kit", hasTests: true)))])
    }

    @Test func flutterProjectWithExactVersionAndPlatforms() throws {
        let folder = try TemporaryFolder()
        try folder.write("app/pubspec.yaml", Fixture.flutterPubspec)
        try folder.folder("app/ios")
        try folder.folder("app/android")
        try folder.folder("app/test")
        // The ios/ folder of a Flutter app is not a separate project.
        try Fixture.xcodeProject(in: folder, directory: "app/ios", name: "Runner", schemes: [("Runner", false)])
        let report = detect(folder)
        #expect(report.projects.count == 1)
        guard case .flutter(let flutter)? = report.projects.first?.kind else {
            Issue.record("no Flutter project")
            return
        }
        #expect(report.projects.first?.directory == "app")
        #expect(flutter.name == "shop")
        #expect(flutter.platforms == ["ios", "android"])
        #expect(flutter.pinnedFlutterVersion == "3.47.8")
        #expect(flutter.hasTests)
    }

    @Test func flutterRangeIsNotPinnedAndDartPackagesAreSkipped() throws {
        let folder = try TemporaryFolder()
        try folder.write("a/pubspec.yaml", Fixture.flutterPubspec.replacingOccurrences(of: "flutter: 3.47.8", with: "flutter: \">=3.41.0\""))
        try folder.write("b/pubspec.yaml", "name: dart_only\nenvironment:\n  sdk: ^3.13.0\n")
        let projects = detect(folder).projects
        #expect(projects.count == 1)
        guard case .flutter(let flutter)? = projects.first?.kind else {
            Issue.record("no Flutter project")
            return
        }
        #expect(flutter.pinnedFlutterVersion == nil)
    }

    @Test(arguments: [
        (["package-lock.json"], nil as String?, PackageManager.npm),
        (["yarn.lock"], nil, .yarnClassic),
        (["yarn.lock", ".yarnrc.yml"], nil, .yarnBerry),
        (["pnpm-lock.yaml"], nil, .pnpm),
        (["bun.lock"], nil, .bun),
        (["package-lock.json"], "pnpm@10.18.0", .pnpm),
        ([], "yarn@1.22.22", .yarnClassic)
    ])
    func packageManagerFromLockfileOrCorepack(files: [String], declared: String?, expected: PackageManager) {
        #expect(ManifestReader.packageManager(declared: declared, names: Set(files)) == expected)
    }

    @Test func reactNativeAppWithNativeFolders() throws {
        let folder = try TemporaryFolder()
        try folder.write("package.json", """
        {"name": "Shop", "scripts": {"lint": "eslint .", "test": "jest", "start": "react-native start"},
         "dependencies": {"react-native": "0.87.0"}}
        """)
        try folder.write("yarn.lock")
        try folder.write(".nvmrc", "24\n")
        try folder.write("Gemfile", "gem 'cocoapods'\n")
        try folder.folder("android/app")
        try Fixture.xcodeProject(in: folder, directory: "ios", name: "Shop", schemes: [("Shop", true)])
        try folder.write("ios/Podfile", "")
        let report = detect(folder)
        #expect(report.projects.count == 1)
        guard case .reactNative(let app)? = report.projects.first?.kind else {
            Issue.record("no React Native app")
            return
        }
        #expect(!app.isExpo && app.hasAndroid && app.usesBundlerForPods)
        #expect(app.packageManager == .yarnClassic)
        #expect(app.nodeVersionFile == ".nvmrc")
        #expect(app.scripts == ["lint", "test", "start"])
        #expect(app.iOS?.workspaceFile == "Shop.xcworkspace")
        #expect(app.iOS?.defaultScheme?.name == "Shop")
        #expect(report.notes.isEmpty)
    }

    @Test func expoAppAndMissingLockfile() throws {
        let folder = try TemporaryFolder()
        try folder.write("package.json", "{\"devDependencies\": {\"expo\": \"~57.0.0\"}}")
        let report = detect(folder)
        guard case .reactNative(let app)? = report.projects.first?.kind else {
            Issue.record("no Expo app")
            return
        }
        #expect(app.isExpo && app.iOS == nil && !app.hasAndroid)
        #expect(report.notes.map(\.message).contains { $0.contains("package-lock.json") })
    }

    @Test func plainNodePackagesAndBrokenJSONAreIgnored() throws {
        let folder = try TemporaryFolder()
        try folder.write("web/package.json", "{\"dependencies\": {\"react\": \"19.0.0\"}}")
        try folder.write("broken/package.json", "{\"dependencies\": {\"react-native\": ")
        try folder.write("deep/package.json", String(repeating: "[", count: 100_000))
        #expect(detect(folder).projects.isEmpty)
    }

    @Test func dependencyFoldersHiddenFoldersAndDepthAreSkipped() throws {
        let folder = try TemporaryFolder()
        try Fixture.xcodeProject(in: folder, directory: "node_modules/pkg")
        try Fixture.xcodeProject(in: folder, directory: ".hidden")
        try Fixture.xcodeProject(in: folder, directory: "a/b/c/d")
        try Fixture.xcodeProject(in: folder, directory: "a/b/c")
        let projects = detect(folder).projects
        #expect(projects.map(\.directory) == ["a/b/c"])
    }

    /// A symbolic link back to the root would make a naive walk loop forever.
    @Test func symbolicLinksAreNotFollowed() throws {
        let folder = try TemporaryFolder()
        try Fixture.xcodeProject(in: folder, directory: "real")
        try FileManager.default.createSymbolicLink(at: folder.url.appendingPathComponent("loop"), withDestinationURL: folder.url)
        try FileManager.default.createSymbolicLink(at: folder.url.appendingPathComponent("alias"),
                                                   withDestinationURL: folder.url.appendingPathComponent("real"))
        #expect(detect(folder).projects.map(\.directory) == ["real"])
    }

    @Test func entryBudgetStopsTheWalk() throws {
        let folder = try TemporaryFolder()
        let crowded = try folder.folder("crowded")
        for index in 0...ProjectDetector.maximumEntries {
            _ = FileManager.default.createFile(atPath: crowded.appendingPathComponent("f\(index)").path, contents: nil)
        }
        let report = detect(folder)
        #expect(report.notes.contains { $0.message.contains("Stopped after") })
    }
}
