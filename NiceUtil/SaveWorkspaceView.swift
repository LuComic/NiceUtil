import SwiftUI
import KeyboardShortcuts

struct SaveWorkspaceView: View {
    @Binding var isPresented: Bool
    var onSave: (String) -> Void
    var onCancel: (() -> Void)? = nil
    @State private var workspaceName = ""

    var body: some View {
        VStack {
            Text("Save Current Workspace")
                .font(.headline)
            TextField("Workspace Name", text: $workspaceName)
                .textFieldStyle(RoundedBorderTextFieldStyle())
            HStack {
                Button("Cancel") {
                    isPresented = false
                    onCancel?()
                }
                Button("Save") {
                    onSave(workspaceName)
                    isPresented = false
                }
                .disabled(workspaceName.isEmpty)
            }
        }
        .padding()
        .frame(width: 300)
    }
}