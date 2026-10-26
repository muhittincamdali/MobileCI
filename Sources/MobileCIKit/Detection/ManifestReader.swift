import Foundation

/// Reads `pubspec.yaml`, `package.json` and `Package.swift`.
enum ManifestReader {
    // MARK: Flutter

    /// A Flutter project: `pubspec.yaml` depends on the Flutter SDK. A pure Dart package
    /// returns `nil`.
    static func flutter(in folder: URL, names: Set<String>) -> FlutterProject? {
        guard let text = try? TextFile.read(folder.appendingPathComponent("pubspec.yaml")),
              case .success(let pubspec) = YAMLLoader.load(text),
              pubspec["dependencies"]?["flutter"]?["sdk"]?.string == "flutter" else {
            return nil
        }
        let platformFolders: Set<String> = ["android", "ios", "web", "macos", "linux", "windows"]
        let constraint = pubspec["environment"]?["flutter"]?.string?.trimmingCharacters(in: .whitespaces)
        return FlutterProject(
            name: pubspec["name"]?.string,
            platforms: names.intersection(platformFolders),
            pinnedFlutterVersion: constraint.flatMap { isExactVersion($0) ? $0 : nil },
            hasFVMConfig: names.contains(".fvmrc"),
            hasTests: names.contains("test")
        )
    }

    /// `3.47.8`: digits and dots only, three parts.
    static func isExactVersion(_ text: String) -> Bool {
        let parts = text.split(separator: ".", omittingEmptySubsequences: false)
        return parts.count == 3 && parts.allSatisfy { !$0.isEmpty && $0.count <= 6 && $0.allSatisfy(\.isASCIIDigit) }
    }

    // MARK: React Native

    static func reactNative(in folder: URL, names: Set<String>, note: (Severity, String) -> Void) -> ReactNativeProject? {
        guard let package = packageJSON(in: folder) else { return nil }
        let dependencies = (package["dependencies"] as? [String: Any] ?? [:])
            .merging(package["devDependencies"] as? [String: Any] ?? [:]) { first, _ in first }
        let isExpo = dependencies["expo"] != nil
        guard dependencies["react-native"] != nil || isExpo else { return nil }

        let scripts = Set((package["scripts"] as? [String: Any] ?? [:]).keys)
        let manager = packageManager(declared: package["packageManager"] as? String, names: names)
        if manager == .bun {
            note(.warning, "bun is not set up by the generated workflow; install it in a step before the dependencies.")
        }
        if !names.contains(lockFile(for: manager)) {
            note(.warning, "No \(lockFile(for: manager)) found; commit the lockfile so CI installs the same dependency versions.")
        }
        var iOS: XcodeProject?
        let iOSFolder = folder.appendingPathComponent("ios", isDirectory: true)
        if names.contains("ios") {
            let entries = DirectoryListing.entries(of: iOSFolder, limit: 1_000, keys: [.isDirectoryKey]).urls
            let listed = entries.map { url in
                ProjectDetector.Entry(name: url.lastPathComponent, isFolder: (try? url.resourceValues(forKeys: [.isDirectoryKey]).isDirectory) ?? false)
            }
            if let projectFile = listed.first(where: { $0.isFolder && $0.name.hasSuffix(".xcodeproj") })?.name {
                iOS = XcodeReader.project(projectFile, in: iOSFolder, entries: listed, note: note)
            }
        }
        return ReactNativeProject(
            name: package["name"] as? String,
            isExpo: isExpo,
            packageManager: manager,
            scripts: scripts,
            nodeVersionFile: [".nvmrc", ".node-version"].first(where: names.contains),
            iOS: iOS,
            hasAndroid: names.contains("android"),
            usesBundlerForPods: names.contains("Gemfile")
        )
    }

    static func packageJSON(in folder: URL) -> [String: Any]? {
        guard let text = try? TextFile.read(folder.appendingPathComponent("package.json")) else { return nil }
        return LargeStack.run {
            (try? JSONSerialization.jsonObject(with: Data(text.utf8))) as? [String: Any]
        }
    }

    /// The `packageManager` field (Corepack) wins over lockfiles.
    static func packageManager(declared: String?, names: Set<String>) -> PackageManager {
        if let declared = declared?.lowercased() {
            if declared.hasPrefix("pnpm@") { return .pnpm }
            if declared.hasPrefix("yarn@1.") { return .yarnClassic }
            if declared.hasPrefix("yarn@") { return .yarnBerry }
            if declared.hasPrefix("bun@") { return .bun }
            if declared.hasPrefix("npm@") { return .npm }
        }
        if names.contains("pnpm-lock.yaml") { return .pnpm }
        if names.contains("bun.lock") || names.contains("bun.lockb") { return .bun }
        if names.contains("yarn.lock") { return names.contains(".yarnrc.yml") ? .yarnBerry : .yarnClassic }
        return .npm
    }

    static func lockFile(for manager: PackageManager) -> String {
        switch manager {
        case .npm: return "package-lock.json"
        case .yarnClassic, .yarnBerry: return "yarn.lock"
        case .pnpm: return "pnpm-lock.yaml"
        case .bun: return "bun.lock"
        }
    }

    // MARK: Swift package

    /// The `name:` of `Package(name: "…")`, read as text: evaluating a manifest runs code.
    static func swiftPackage(in folder: URL, names: Set<String>) -> SwiftPackage {
        let text = (try? TextFile.read(folder.appendingPathComponent("Package.swift"))) ?? ""
        var name: String?
        if let range = text.range(of: "Package(") {
            let rest = text[range.upperBound...].drop { $0.isWhitespace }
            if rest.hasPrefix("name:") {
                let value = rest.dropFirst("name:".count).drop { $0.isWhitespace }
                if value.first == "\"", let end = value.dropFirst().firstIndex(of: "\"") {
                    name = String(value[value.index(after: value.startIndex)..<end])
                }
            }
        }
        return SwiftPackage(name: name, hasTests: names.contains("Tests"))
    }
}
