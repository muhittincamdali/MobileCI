/// Workflows for React Native and Expo apps: lint, type-check and test on Linux, plus a debug
/// Android build and an iOS simulator build for the native folders that exist.
enum ReactNativeWorkflow {
    /// `package.json` scripts the checks job runs, in this order, when they exist.
    static let checkScripts: [(script: String, step: String)] = [
        ("lint", "Lint"),
        ("typecheck", "Type-check"),
        ("type-check", "Type-check"),
        ("tsc", "Type-check"),
        ("test", "Test")
    ]

    static func write(_ project: ReactNativeProject, directory: String, fileName: String,
                      options: GeneratorOptions, into writer: inout WorkflowWriter) throws(GeneratorError) {
        guard project.packageManager != .bun else {
            throw .unsupported("bun projects are not supported yet: generate with a package.json lockfile for npm, Yarn or pnpm, or add oven-sh/setup-bun by hand.")
        }
        writer.header(kind: project.isExpo ? "Expo app" : "React Native app", directory: directory,
                      fileName: fileName, options: options)

        writer.job("checks", name: "Lint and test", runner: options.linuxRunner, timeout: 15)
        writer.workingDirectory(directory)
        writer.steps()
        writer.checkout()
        installDependencies(project, directory: directory, options: options, into: &writer)
        var typeChecked = false
        for (script, step) in checkScripts where project.scripts.contains(script) {
            if step == "Type-check" {
                if typeChecked { continue }
                typeChecked = true
            }
            writer.step(step, run: command(for: script, manager: project.packageManager))
        }
        if project.isExpo, !project.hasAndroid, project.iOS == nil {
            writer.blank()
            writer.add(3, "# No ios/ or android/ folder: native builds of an Expo app run on EAS Build")
            writer.add(3, "# (https://docs.expo.dev/build/building-on-ci/).")
        }

        if project.hasAndroid {
            writer.blank()
            writer.job("android", name: "Build Android (debug APK)", runner: options.linuxRunner, timeout: 45)
            writer.workingDirectory(directory)
            writer.steps()
            writer.checkout()
            installDependencies(project, directory: directory, options: options, into: &writer)
            writer.uses("Set up Java", .setupJava, with: [
                ("distribution", "temurin"),
                ("java-version", WorkflowWriter.quoted(options.javaVersion)),
                ("cache", "gradle")
            ])
            writer.step("Build the APK", run: "./gradlew assembleDebug --no-daemon", workingDirectory: directory.joinedPath("android"))
        }

        if let iOS = project.iOS {
            try writeiOS(iOS, project: project, directory: directory, options: options, into: &writer)
        }
    }

    private static func writeiOS(_ iOS: XcodeProject, project: ReactNativeProject, directory: String,
                                 options: GeneratorOptions, into writer: inout WorkflowWriter) throws(GeneratorError) {
        let scheme = try AppleWorkflow.chooseScheme(in: iOS, options: options)
        let workspace = iOS.workspaceFile ?? String(iOS.projectFile.dropLast(".xcodeproj".count)) + ".xcworkspace"
        try Validation.check("workspace file", workspace, allowed: Validation.name)
        let iOSFolder = directory.joinedPath("ios")
        writer.blank()
        writer.job("ios", name: "Build iOS (simulator)", runner: options.macOSRunner, timeout: 60)
        writer.developerDirectory(options)
        writer.workingDirectory(directory)
        writer.steps()
        writer.checkout()
        installDependencies(project, directory: directory, options: options, into: &writer)
        // React Native templates keep the Gemfile that pins CocoaPods in the project root.
        let pods = project.usesBundlerForPods ? "bundle install\ncd ios\nbundle exec pod install" : "cd ios\npod install"
        writer.step("Install CocoaPods dependencies", run: pods)
        let build = [
            "set -o pipefail",
            "xcodebuild build \\",
            "  -workspace \"$WORKSPACE\" \\",
            "  -scheme \"$SCHEME\" \\",
            "  -configuration Debug \\",
            "  -destination 'generic/platform=iOS Simulator' \\",
            "  CODE_SIGNING_ALLOWED=NO \\",
            "  -quiet"
        ].joined(separator: "\n")
        writer.step("Build for the simulator", run: build, workingDirectory: iOSFolder,
                    env: [("WORKSPACE", workspace), ("SCHEME", scheme.name)])
    }

    private static func installDependencies(_ project: ReactNativeProject, directory: String,
                                            options: GeneratorOptions, into writer: inout WorkflowWriter) {
        var inputs: [(String, String)] = []
        if let file = project.nodeVersionFile {
            inputs.append(("node-version-file", WorkflowWriter.quoted(directory.joinedPath(file))))
        } else {
            inputs.append(("node-version", WorkflowWriter.quoted(options.nodeVersion)))
        }
        switch project.packageManager {
        case .npm:
            inputs += [("cache", "npm"), ("cache-dependency-path", WorkflowWriter.quoted(directory.joinedPath("package-lock.json")))]
        case .yarnClassic:
            inputs += [("cache", "yarn"), ("cache-dependency-path", WorkflowWriter.quoted(directory.joinedPath("yarn.lock")))]
        case .yarnBerry, .pnpm, .bun:
            break
        }
        writer.uses("Set up Node.js", .setupNode, with: inputs)
        if project.packageManager == .pnpm || project.packageManager == .yarnBerry {
            writer.step("Enable Corepack", run: "corepack enable")
        }
        writer.step("Install dependencies", run: installCommand(project.packageManager))
    }

    static func installCommand(_ manager: PackageManager) -> String {
        switch manager {
        case .npm: return "npm ci"
        case .yarnClassic: return "yarn install --frozen-lockfile"
        case .yarnBerry: return "yarn install --immutable"
        case .pnpm: return "pnpm install --frozen-lockfile"
        case .bun: return "bun install --frozen-lockfile"
        }
    }

    static func command(for script: String, manager: PackageManager) -> String {
        switch manager {
        case .npm: return script == "test" ? "npm test" : "npm run \(script)"
        case .yarnClassic, .yarnBerry: return "yarn \(script)"
        case .pnpm: return script == "test" ? "pnpm test" : "pnpm run \(script)"
        case .bun: return "bun run \(script)"
        }
    }
}
