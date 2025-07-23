import SwiftUI
import KeyboardShortcuts

struct ShortcutRecorderView: View {
    let workspace: Workspace
    var onSave: () -> Void
    var onCancel: () -> Void

    var body: some View {
        VStack {
            Text("Record Shortcut for \(workspace.name)")
                .font(.headline)
            KeyboardShortcuts.Recorder(for: .init("workspace_\(workspace.id.uuidString)"))
            HStack {
                Button("Cancel", action: onCancel)
                Button("Save", action: onSave)
            }
        }
        .padding()
        .frame(width: 300)
    }
}
