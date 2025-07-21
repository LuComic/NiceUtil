import SwiftUI

struct SaveWorkspaceView: View {
    @Binding var isPresented: Bool
    var onSave: (String) -> Void
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
