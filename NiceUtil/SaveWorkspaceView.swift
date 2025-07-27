import SwiftUI
import KeyboardShortcuts
import UniformTypeIdentifiers

struct AppDisplayInfo: Identifiable, Hashable {
    let id = UUID()
    let url: URL
    let origin: String

    static func == (lhs: AppDisplayInfo, rhs: AppDisplayInfo) -> Bool {
        lhs.url == rhs.url
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(url)
    }
}

struct SaveWorkspaceView: View {
    @Binding var isPresented: Bool
    var onSave: (String, [URL]) -> Void
    var onCancel: (() -> Void)? = nil
    var onAddAllRunningApps: (() -> [URL])? = nil

    @State private var workspaceName = ""
    @State private var selectedApps: Set<AppDisplayInfo>
    @State private var searchQuery = ""
    @State private var allAvailableApps: [AppDisplayInfo]
    @State private var allInstalledApps: [AppDisplayInfo] = []

    init(isPresented: Binding<Bool>, preSelectedApps: [URL], onSave: @escaping (String, [URL]) -> Void, onCancel: (() -> Void)? = nil, onAddAllRunningApps: (() -> [URL])? = nil) {
        self._isPresented = isPresented
        self.onSave = onSave
        self.onCancel = onCancel
        self.onAddAllRunningApps = onAddAllRunningApps

        // Initialize allAvailableApps with preSelectedApps (from current space)
        let preSelectedDisplayInfos = preSelectedApps.map { AppDisplayInfo(url: $0, origin: "from current space") }
        self._allAvailableApps = State(initialValue: preSelectedDisplayInfos.sorted { $0.url.lastPathComponent.lowercased() < $1.url.lastPathComponent.lowercased() })

        // Initialize selectedApps with preSelectedApps (from current space)
        self._selectedApps = State(initialValue: Set(preSelectedDisplayInfos))
    }

    var filteredApps: [AppDisplayInfo] {
        if searchQuery.isEmpty {
            return allAvailableApps
        } else {
            return allInstalledApps.filter { $0.url.lastPathComponent.lowercased().contains(searchQuery.lowercased()) }
        }
    }

    var body: some View {
        VStack {
            Text("Save Current Workspace")
                .font(.headline)

            TextField("Workspace Name", text: $workspaceName)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .padding(.bottom)

            TextField("Search Applications", text: $searchQuery)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .padding(.bottom)
                .onAppear {
                    loadAllInstalledApplications()
                }

            List {
                ForEach(filteredApps) { appInfo in
                    if searchQuery.isEmpty {
                        Toggle(isOn: Binding(
                            get: { selectedApps.contains(appInfo) },
                            set: { isSelected in
                                if isSelected {
                                    selectedApps.insert(appInfo)
                                } else {
                                    selectedApps.remove(appInfo)
                                }
                            }
                        )) {
                            HStack {
                                Image(nsImage: NSWorkspace.shared.icon(forFile: appInfo.url.path))
                                    .resizable()
                                    .frame(width: 20, height: 20)
                                Text("\(appInfo.url.lastPathComponent.replacingOccurrences(of: ".app", with: "")) (\(appInfo.origin))")
                            }
                        }
                    } else {
                        HStack {
                            Image(nsImage: NSWorkspace.shared.icon(forFile: appInfo.url.path))
                                .resizable()
                                .frame(width: 20, height: 20)
                            Text("\(appInfo.url.lastPathComponent.replacingOccurrences(of: ".app", with: "")) (\(appInfo.origin))")
                            Spacer()
                            Button(action: {
                                if !allAvailableApps.contains(appInfo) {
                                    allAvailableApps.append(appInfo)
                                    allAvailableApps.sort { $0.url.lastPathComponent.lowercased() < $1.url.lastPathComponent.lowercased() }
                                }
                                selectedApps.insert(appInfo)
                                searchQuery = ""
                            }) {
                                Image(systemName: "plus.circle.fill")
                            }
                            .buttonStyle(BorderlessButtonStyle())
                        }
                    }
                }
            }
            .frame(minHeight: 150, maxHeight: 300)
            .border(Color.gray, width: 0.5)
            .padding(.bottom)

            HStack {
                Button("Add All Running Apps") {
                    if let allRunning = onAddAllRunningApps?() {
                        for url in allRunning {
                            let newAppInfo = AppDisplayInfo(url: url, origin: "from all workspaces")
                            if !allAvailableApps.contains(newAppInfo) {
                                allAvailableApps.append(newAppInfo)
                                selectedApps.insert(newAppInfo)
                            }
                        }
                        allAvailableApps.sort { $0.url.lastPathComponent.lowercased() < $1.url.lastPathComponent.lowercased() }
                    }
                }
            }
            .padding(.bottom)

            HStack {
                Button("Cancel") {
                    isPresented = false
                    onCancel?()
                }
                Button("Save") {
                    onSave(workspaceName, Array(selectedApps).map { $0.url })
                    isPresented = false
                }
                .disabled(workspaceName.isEmpty || selectedApps.isEmpty)
            }
        }
        .padding()
        .frame(width: 400)
    }

    private func loadAllInstalledApplications() {
        var installedApps: Set<URL> = []
        let fileManager = FileManager.default

        let appDirs = [
            "/Applications",
            "/System/Applications",
            "/System/Library/CoreServices",
            ("~/Applications" as NSString).expandingTildeInPath
        ]

        for dir in appDirs {
            let url = URL(fileURLWithPath: dir)
            if let enumerator = fileManager.enumerator(at: url, includingPropertiesForKeys: [.isDirectoryKey], options: [.skipsHiddenFiles, .skipsPackageDescendants]) {
                for case let fileURL as URL in enumerator {
                    if fileURL.pathExtension == "app" {
                        installedApps.insert(fileURL)
                    }
                }
            }
        }
        
        // Filter out NiceUtil itself
        if let currentAppBundleIdentifier = Bundle.main.bundleIdentifier {
            installedApps = Set(installedApps.filter { url in
                Bundle(url: url)?.bundleIdentifier != currentAppBundleIdentifier
            })
        }

        self.allInstalledApps = installedApps.map { AppDisplayInfo(url: $0, origin: "installed") }.sorted { $0.url.lastPathComponent.lowercased() < $1.url.lastPathComponent.lowercased() }
    }
}
