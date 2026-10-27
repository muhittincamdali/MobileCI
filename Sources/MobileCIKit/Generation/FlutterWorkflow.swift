/// Workflows for Flutter apps and packages: analyze and test on Linux, plus a debug Android
/// build and an iOS simulator build when the platform folders exist.
enum FlutterWorkflow {
    static func write(_ project: FlutterProject, directory: String, fileName: String,
                      options: GeneratorOptions, into writer: inout WorkflowWriter) {
        writer.header(kind: "Flutter project", directory: directory, fileName: fileName, options: options)

        writer.job("analyze-and-test", name: project.hasTests ? "Analyze and test" : "Analyze",
                   runner: options.linuxRunner, timeout: 20)
        writer.workingDirectory(directory)
        writer.steps()
        writer.checkout()
        setUpFlutter(project, directory: directory, options: options, into: &writer)
        writer.step("Analyze", run: "flutter analyze")
        if project.hasTests {
            writer.step("Test", run: "flutter test")
        }

        if project.platforms.contains("android") {
            writer.blank()
            writer.job("android", name: "Build Android (debug APK)", runner: options.linuxRunner, timeout: 30)
            writer.workingDirectory(directory)
            writer.steps()
            writer.checkout()
            writer.uses("Set up Java", .setupJava, with: [
                ("distribution", "temurin"),
                ("java-version", WorkflowWriter.quoted(options.javaVersion))
            ])
            setUpFlutter(project, directory: directory, options: options, into: &writer)
            writer.step("Build the APK", run: "flutter build apk --debug")
        }

        if project.platforms.contains("ios") {
            writer.blank()
            writer.job("ios", name: "Build iOS (simulator)", runner: options.macOSRunner, timeout: 45)
            writer.developerDirectory(options)
            writer.workingDirectory(directory)
            writer.steps()
            writer.checkout()
            setUpFlutter(project, directory: directory, options: options, into: &writer)
            writer.step("Build for the simulator", run: "flutter build ios --simulator --debug")
        }
    }

    private static func setUpFlutter(_ project: FlutterProject, directory: String,
                                     options: GeneratorOptions, into writer: inout WorkflowWriter) {
        var inputs = [("channel", "stable")]
        if project.pinnedFlutterVersion != nil {
            inputs.append(("flutter-version-file", WorkflowWriter.quoted(directory.joinedPath("pubspec.yaml"))))
        } else if project.hasFVMConfig {
            inputs.append(("flutter-version-file", WorkflowWriter.quoted(directory.joinedPath(".fvmrc"))))
        } else {
            inputs.append(("flutter-version", WorkflowWriter.quoted(options.flutterVersion)))
        }
        inputs.append(("cache", "true"))
        writer.uses("Set up Flutter", .flutter, with: inputs)
        writer.step("Install dependencies", run: "flutter pub get")
    }
}
