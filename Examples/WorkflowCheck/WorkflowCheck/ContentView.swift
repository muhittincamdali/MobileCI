import MobileCIKit
import SwiftUI

struct ContentView: View {
    @State var model: CheckModel
    @State private var showsEditor = false

    var body: some View {
        NavigationStack {
            List {
                Section {
                    Picker("Workflow", selection: $model.sample) {
                        ForEach(Sample.allCases) { sample in
                            Text(sample.title).tag(sample)
                        }
                    }
                    Button("Edit the YAML") { showsEditor = true }
                }
                Section(model.summary) {
                    if model.findings.isEmpty {
                        Label("This workflow passes every rule.", systemImage: "checkmark.seal.fill")
                            .foregroundStyle(.blue)
                    }
                    ForEach(Array(model.findings.enumerated()), id: \.offset) { _, finding in
                        FindingRow(finding: finding)
                    }
                }
                Section {
                    Text(AppVersion.label(info: Bundle.main.infoDictionary))
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }
            }
            .navigationTitle("Workflow Check")
            .sheet(isPresented: $showsEditor) {
                NavigationStack {
                    TextEditor(text: $model.text)
                        .font(.system(.footnote, design: .monospaced))
                        .autocorrectionDisabled()
                        .textInputAutocapitalization(.never)
                        .navigationTitle("workflow.yml")
                        .navigationBarTitleDisplayMode(.inline)
                        .toolbar {
                            Button("Done") { showsEditor = false }
                        }
                }
            }
        }
        .tint(.blue)
    }
}

struct FindingRow: View {
    let finding: Finding

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Image(systemName: symbol)
                    .foregroundStyle(color)
                    .accessibilityLabel(finding.severity.rawValue)
                Text("\(finding.rule.rawValue) \(finding.rule.name)")
                    .font(.subheadline.monospaced().weight(.semibold))
                Spacer()
                Text("line \(finding.location.line)")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            Text(finding.message)
                .font(.footnote)
        }
        .padding(.vertical, 2)
    }

    private var symbol: String {
        switch finding.severity {
        case .error: return "xmark.octagon.fill"
        case .warning: return "exclamationmark.triangle.fill"
        case .note: return "info.circle.fill"
        }
    }

    private var color: Color {
        switch finding.severity {
        case .error: return .indigo
        case .warning: return .blue
        case .note: return .cyan
        }
    }
}

#Preview {
    ContentView(model: CheckModel())
}
