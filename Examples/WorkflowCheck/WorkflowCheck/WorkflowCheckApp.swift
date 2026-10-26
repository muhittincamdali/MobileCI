import SwiftUI

@main
struct WorkflowCheckApp: App {
    /// `-sample injection` starts on another sample (used by scripts/capture-example-screens.sh).
    private let initialSample = UserDefaults.standard.string(forKey: "sample").flatMap(Sample.init(rawValue:)) ?? .firstWorkflow

    var body: some Scene {
        WindowGroup {
            ContentView(model: CheckModel(sample: initialSample))
        }
    }
}
