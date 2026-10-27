import Foundation
import MobileCIKit

/// `mobileci detect --format json`.
enum DetectionJSON {
    static func render(_ report: DetectionReport) -> String {
        let document: [String: Any] = [
            "projects": report.projects.map(project),
            "notes": report.notes.map { ["directory": $0.directory, "severity": $0.severity.rawValue, "message": $0.message] }
        ]
        let options: JSONSerialization.WritingOptions = [.prettyPrinted, .sortedKeys, .withoutEscapingSlashes]
        guard let data = try? JSONSerialization.data(withJSONObject: document, options: options),
              let text = String(data: data, encoding: .utf8) else {
            preconditionFailure("A report of strings, numbers and booleans is valid JSON.")
        }
        return text + "\n"
    }

    private static func project(_ project: DetectedProject) -> [String: Any] {
        var entry: [String: Any] = [
            "directory": project.directory,
            "kind": project.kindName,
            "workflow": ".github/workflows/" + WorkflowGenerator.fileName(for: project)
        ]
        switch project.kind {
        case .xcode(let xcode):
            entry["xcode"] = self.xcode(xcode)
        case .swiftPackage(let package):
            entry["package"] = ["name": nullable(package.name), "hasTests": package.hasTests]
        case .flutter(let flutter):
            entry["flutter"] = [
                "name": nullable(flutter.name),
                "platforms": flutter.platforms.sorted(),
                "pinnedFlutterVersion": nullable(flutter.pinnedFlutterVersion),
                "hasFVMConfig": flutter.hasFVMConfig,
                "hasTests": flutter.hasTests
            ]
        case .reactNative(let app):
            entry["reactNative"] = [
                "name": nullable(app.name),
                "isExpo": app.isExpo,
                "packageManager": app.packageManager.rawValue,
                "scripts": app.scripts.sorted(),
                "nodeVersionFile": nullable(app.nodeVersionFile),
                "ios": nullable(app.iOS.map(xcode)),
                "hasAndroid": app.hasAndroid
            ]
        }
        return entry
    }

    /// `null` in the JSON for a missing value.
    private static func nullable(_ value: Any?) -> Any {
        value ?? NSNull()
    }

    private static func xcode(_ xcode: XcodeProject) -> [String: Any] {
        [
            "project": xcode.projectFile,
            "workspace": nullable(xcode.workspaceFile),
            "schemes": xcode.schemes.map { ["name": $0.name, "hasTests": $0.hasTests] },
            "platform": xcode.platform.rawValue,
            "usesCocoaPods": xcode.usesCocoaPods,
            "usesSwiftPackages": xcode.usesSwiftPackages
        ]
    }
}
