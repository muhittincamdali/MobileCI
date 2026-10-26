import Foundation
@testable import MobileCIKit
import Testing

struct GeneratorTests {
    static let iOSApp = XcodeProject(projectFile: "App.xcodeproj", workspaceFile: nil,
                                     schemes: [XcodeScheme(name: "App", hasTests: true)], platform: .iOS,
                                     usesCocoaPods: false, usesBundler: false, usesSwiftPackages: false)

    static let projects: [DetectedProject] = [
        DetectedProject(directory: ".", kind: .xcode(iOSApp)),
        DetectedProject(directory: "apps/ios", kind: .xcode(XcodeProject(
            projectFile: "Shop.xcodeproj", workspaceFile: "Shop.xcworkspace",
            schemes: [XcodeScheme(name: "Shop (Staging)", hasTests: false)], platform: .iOS,
            usesCocoaPods: true, usesBundler: true, usesSwiftPackages: true))),
        DetectedProject(directory: ".", kind: .xcode(XcodeProject(
            projectFile: "Mac.xcodeproj", workspaceFile: nil, schemes: [XcodeScheme(name: "Mac", hasTests: true)],
            platform: .macOS, usesCocoaPods: false, usesBundler: false, usesSwiftPackages: false))),
        DetectedProject(directory: ".", kind: .swiftPackage(SwiftPackage(name: "Kit", hasTests: true))),
        DetectedProject(directory: "packages/kit", kind: .swiftPackage(SwiftPackage(name: nil, hasTests: false))),
        DetectedProject(directory: "app", kind: .flutter(FlutterProject(
            name: "shop", platforms: ["android", "ios", "web"], pinnedFlutterVersion: "3.47.8", hasFVMConfig: false, hasTests: true))),
        DetectedProject(directory: ".", kind: .flutter(FlutterProject(
            name: "pkg", platforms: [], pinnedFlutterVersion: nil, hasFVMConfig: true, hasTests: false))),
        DetectedProject(directory: "mobile", kind: .reactNative(ReactNativeProject(
            name: "Shop", isExpo: false, packageManager: .yarnClassic, scripts: ["lint", "typecheck", "tsc", "test"],
            nodeVersionFile: ".nvmrc", iOS: XcodeProject(projectFile: "Shop.xcodeproj", workspaceFile: nil,
                                                          schemes: [XcodeScheme(name: "Shop", hasTests: false)], platform: .iOS,
                                                          usesCocoaPods: true, usesBundler: false, usesSwiftPackages: false),
            hasAndroid: true, usesBundlerForPods: true))),
        DetectedProject(directory: ".", kind: .reactNative(ReactNativeProject(
            name: "expo-app", isExpo: true, packageManager: .pnpm, scripts: ["test"], nodeVersionFile: nil,
            iOS: nil, hasAndroid: false, usesBundlerForPods: false))),
        DetectedProject(directory: ".", kind: .reactNative(ReactNativeProject(
            name: "berry", isExpo: false, packageManager: .yarnBerry, scripts: [], nodeVersionFile: ".node-version",
            iOS: nil, hasAndroid: true, usesBundlerForPods: false))),
        DetectedProject(directory: ".", kind: .reactNative(ReactNativeProject(
            name: "npm", isExpo: false, packageManager: .npm, scripts: ["test"], nodeVersionFile: nil,
            iOS: nil, hasAndroid: false, usesBundlerForPods: false)))
    ]

    /// The generator's promise: valid YAML that MobileCI's own rules accept, for every kind.
    @Test(arguments: projects)
    func generatedWorkflowsPassEveryRule(project: DetectedProject) throws {
        let workflow = try WorkflowGenerator().workflow(for: project)
        #expect(throws: Never.self) { try YAMLLoader.load(workflow.contents).get() }
        let findings = WorkflowLinter().lint(text: workflow.contents, path: workflow.fileName)
        #expect(findings.isEmpty, "\(findings.map { "\($0.rule.rawValue) line \($0.location.line): \($0.message)" })")
    }

    @Test func iOSWorkflowContents() throws {
        let text = try WorkflowGenerator().workflow(for: Self.projects[0]).contents
        #expect(text.contains("runs-on: macos-26"))
        #expect(text.contains("DEVELOPER_DIR: /Applications/Xcode_26.6.app/Contents/Developer"))
        #expect(text.contains("SCHEME: 'App'"))
        #expect(text.contains("DESTINATION: 'platform=iOS Simulator,name=iPhone 17,OS=latest'"))
        #expect(text.contains("xcodebuild test \\"))
        #expect(!text.contains("paths:"))
        #expect(!text.contains("pod install"))
    }

    @Test func subfolderWorkspaceWithPodsAndPackages() throws {
        let workflow = try WorkflowGenerator().workflow(for: Self.projects[1])
        let text = workflow.contents
        #expect(workflow.fileName == "ios-apps-ios.yml")
        #expect(text.contains("name: iOS app (apps/ios)"))
        #expect(text.contains("      - 'apps/ios/**'\n      - '.github/workflows/ios-apps-ios.yml'"))
        #expect(text.contains("working-directory: 'apps/ios'"))
        #expect(text.contains("bundle exec pod install"))
        #expect(text.contains("WORKSPACE: 'Shop.xcworkspace'"))
        #expect(text.contains("SCHEME: 'Shop (Staging)'"))
        #expect(text.contains("xcodebuild build \\"))
        #expect(text.contains("-clonedSourcePackagesDirPath SourcePackages"))
        #expect(text.contains("hashFiles('apps/ios/**/Package.resolved')"))
    }

    @Test func flutterJobsFollowThePlatformFolders() throws {
        let app = try WorkflowGenerator().workflow(for: Self.projects[5]).contents
        #expect(app.contains("flutter-version-file: 'app/pubspec.yaml'"))
        #expect(app.contains("flutter build apk --debug") && app.contains("flutter build ios --simulator --debug"))
        #expect(app.contains("java-version: '17'"))
        let package = try WorkflowGenerator().workflow(for: Self.projects[6]).contents
        #expect(package.contains("flutter-version-file: '.fvmrc'"))
        #expect(!package.contains("android:") && !package.contains("flutter test"))
    }

    @Test func reactNativeScriptsAndNativeBuilds() throws {
        let text = try WorkflowGenerator().workflow(for: Self.projects[7]).contents
        #expect(text.contains("yarn install --frozen-lockfile"))
        #expect(text.contains("node-version-file: 'mobile/.nvmrc'"))
        #expect(text.contains("run: yarn lint") && text.contains("run: yarn test"))
        // typecheck and tsc both mean type checking; only the first one runs.
        #expect(text.components(separatedBy: "Type-check").count == 2)
        #expect(text.contains("working-directory: 'mobile/android'"))
        #expect(text.contains("bundle install\n          cd ios\n          bundle exec pod install"))
        #expect(text.contains("WORKSPACE: 'Shop.xcworkspace'"))
        let expo = try WorkflowGenerator().workflow(for: Self.projects[8])
        #expect(expo.fileName == "expo.yml")
        #expect(expo.contents.contains("corepack enable") && expo.contents.contains("pnpm install --frozen-lockfile"))
        #expect(expo.contents.contains("EAS Build"))
    }

    @Test func optionsChangeTheValues() throws {
        var options = GeneratorOptions()
        options.xcodeVersion = "27.0"
        options.macOSRunner = "macos-26-xlarge"
        options.simulator = "iPhone 17 Pro"
        options.branch = "release/2.x"
        let text = try WorkflowGenerator(options: options).workflow(for: Self.projects[0]).contents
        #expect(text.contains("Xcode_27.0.app") && text.contains("runs-on: macos-26-xlarge"))
        #expect(text.contains("name=iPhone 17 Pro,") && text.contains("branches: ['release/2.x']"))
    }

    @Test func projectWithoutSharedSchemeIsRefused() {
        let project = DetectedProject(directory: ".", kind: .xcode(XcodeProject(
            projectFile: "App.xcodeproj", workspaceFile: nil, schemes: [], platform: .iOS,
            usesCocoaPods: false, usesBundler: false, usesSwiftPackages: false)))
        #expect(throws: GeneratorError.noScheme(project: "App.xcodeproj")) {
            try WorkflowGenerator().workflow(for: project)
        }
    }

    @Test func requestedSchemeMustExist() throws {
        var options = GeneratorOptions()
        options.scheme = "Other"
        #expect(throws: GeneratorError.unknownScheme("Other", available: ["App"])) {
            try WorkflowGenerator(options: options).workflow(for: Self.projects[0])
        }
    }

    /// Values land in YAML and in shell scripts; anything that could end a quote, start an
    /// expression or a new line is refused.
    @Test(arguments: ["App'; rm -rf ~", "App\nrun: x", "${{ secrets.TOKEN }}", "App`id`", "App$HOME", "", " App", String(repeating: "a", count: 201)])
    func unsafeSchemeNamesAreRefused(name: String) {
        let project = DetectedProject(directory: ".", kind: .xcode(XcodeProject(
            projectFile: "App.xcodeproj", workspaceFile: nil, schemes: [XcodeScheme(name: name, hasTests: true)],
            platform: .iOS, usesCocoaPods: false, usesBundler: false, usesSwiftPackages: false)))
        #expect(throws: GeneratorError.self) { try WorkflowGenerator().workflow(for: project) }
    }

    @Test(arguments: ["../outside", "/abs", "a/./b", "a//b", "a/..", "a'b"])
    func unsafeFoldersAreRefused(directory: String) {
        let project = DetectedProject(directory: directory, kind: .swiftPackage(SwiftPackage(name: nil, hasTests: true)))
        #expect(throws: GeneratorError.self) { try WorkflowGenerator().workflow(for: project) }
    }

    @Test func unsafeOptionsAreRefused() {
        var options = GeneratorOptions()
        options.branch = "main\non: push"
        #expect(throws: GeneratorError.self) { try options.validated() }
        options = GeneratorOptions()
        options.xcodeVersion = "26.6 && curl x"
        #expect(throws: GeneratorError.self) { try options.validated() }
    }

    @Test func bunIsNotSupported() {
        let project = DetectedProject(directory: ".", kind: .reactNative(ReactNativeProject(
            name: nil, isExpo: false, packageManager: .bun, scripts: [], nodeVersionFile: nil, iOS: nil,
            hasAndroid: false, usesBundlerForPods: false)))
        #expect(throws: GeneratorError.self) { try WorkflowGenerator().workflow(for: project) }
    }

    @Test func chosenFileNameIsUsedInThePathFilter() throws {
        let workflow = try WorkflowGenerator().workflow(for: Self.projects[1], fileName: "ci.yml")
        #expect(workflow.fileName == "ci.yml")
        #expect(workflow.contents.contains("- '.github/workflows/ci.yml'"))
        for bad in ["ci", "../ci.yml", ".yml", "c i.yml", "ci.yml\n"] {
            #expect(throws: GeneratorError.self) { try WorkflowGenerator().workflow(for: Self.projects[1], fileName: bad) }
        }
    }

    @Test func fileNames() {
        let names = Self.projects.map(WorkflowGenerator.fileName(for:))
        #expect(names == ["ios.yml", "ios-apps-ios.yml", "macos.yml", "swift-package.yml", "swift-package-packages-kit.yml",
                          "flutter-app.yml", "flutter.yml", "react-native-mobile.yml", "expo.yml", "react-native.yml",
                          "react-native.yml"])
        let odd = DetectedProject(directory: "Ünïcode Apps/--x--", kind: .swiftPackage(SwiftPackage(name: nil, hasTests: false)))
        #expect(WorkflowGenerator.fileName(for: odd) == "swift-package-n-code-apps-x.yml")
    }
}
