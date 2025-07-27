import SwiftUI
import Cocoa
import KeyboardShortcuts

@main
struct NiceUtilApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate

    var body: some Scene {
        Settings {
            EmptyView()
        }
    }
}

class AppDelegate: NSObject, NSApplicationDelegate {
    var statusItem: NSStatusItem?
    var popover: NSPopover?
    var timer: Timer?

    func applicationDidFinishLaunching(_ aNotification: Notification) {
        // Create the status item
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)

        // Initial setup of the space indicator
        updateSpaceIndicator()

        // Create the menu
        populateWorkspacesMenu()

        // Set up a timer to refresh the space indicator
        timer = Timer.scheduledTimer(timeInterval: 1.0, target: self, selector: #selector(updateSpaceIndicator), userInfo: nil, repeats: true)

        // Add shortcut listeners
        let workspaces = loadWorkspaces()
        for workspace in workspaces {
            let shortcutName = KeyboardShortcuts.Name("workspace_\(workspace.id.uuidString)")
            KeyboardShortcuts.onKeyDown(for: shortcutName) { [weak self] in
                self?.launchWorkspaceWithTracking(workspace)
            }
        }
    }

    @MainActor
    func populateWorkspacesMenu() {
        let menu = NSMenu()
        menu.addItem(NSMenuItem(title: "Save Current Workspace...", action: #selector(saveWorkspace), keyEquivalent: ""))
        menu.addItem(NSMenuItem.separator())

        let workspaces = loadWorkspaces()
        for workspace in workspaces {
            let submenu = NSMenu()
            // Load option
            let loadItem = NSMenuItem(title: "Load Workspace", action: #selector(loadWorkspaceFromMenu(_:)), keyEquivalent: "")
            loadItem.representedObject = workspace
            submenu.addItem(loadItem)

            // Shortcut options
            let shortcutName = KeyboardShortcuts.Name("workspace_\(workspace.id.uuidString)")
            if KeyboardShortcuts.getShortcut(for: shortcutName) != nil {
                let editItem = NSMenuItem(title: "Edit Shortcut", action: #selector(editShortcut(_:)), keyEquivalent: "")
                editItem.representedObject = workspace
                submenu.addItem(editItem)
                
                let removeItem = NSMenuItem(title: "Remove Shortcut", action: #selector(removeShortcut(_:)), keyEquivalent: "")
                removeItem.representedObject = workspace
                submenu.addItem(removeItem)
            } else {
                let addItem = NSMenuItem(title: "Add Shortcut", action: #selector(addShortcut(_:)), keyEquivalent: "")
                addItem.representedObject = workspace
                submenu.addItem(addItem)
            }

            // Delete option
            let deleteItem = NSMenuItem(title: "Delete", action: #selector(deleteWorkspaceFromMenu(_:)), keyEquivalent: "")
            deleteItem.representedObject = workspace
            submenu.addItem(deleteItem)

            // Main menu item
            let item = NSMenuItem(title: "", action: #selector(loadWorkspaceFromMenu(_:)), keyEquivalent: "")
            let title = NSMutableAttributedString(string: workspace.name)
            if let shortcut = KeyboardShortcuts.getShortcut(for: shortcutName) {
                let shortcutString = "    " + shortcut.description // Add some spacing
                let attributes: [NSAttributedString.Key: Any] = [
                    .foregroundColor: NSColor.gray,
                    .font: NSFont.menuFont(ofSize: NSFont.smallSystemFontSize)
                ]
                let attributedShortcut = NSAttributedString(string: shortcutString, attributes: attributes)
                title.append(attributedShortcut)
            }
            item.attributedTitle = title
            item.representedObject = workspace
            menu.setSubmenu(submenu, for: item)
            menu.addItem(item)
        }

        menu.addItem(NSMenuItem.separator())
        menu.addItem(NSMenuItem(title: "Quit", action: #selector(NSApplication.terminate(_:)), keyEquivalent: "q"))

        statusItem?.menu = menu
    }
    
    func showErrorAlert(message: String) {
        let alert = NSAlert()
        alert.messageText = "NiceUtil Error"
        alert.informativeText = message
        alert.alertStyle = .warning
        alert.runModal()
    }

    @objc func updateSpaceIndicator() {
        let conn = _CGSDefaultConnection()
        let displays = CGSCopyManagedDisplaySpaces(conn) as! [NSDictionary]
        var activeSpaceID = -1
        var totalSpaces = 0
        var activeSpaceNumber = -1

        for d in displays {
            guard let currentSpaces = d["Current Space"] as? [String: Any],
                  let spaces = d["Spaces"] as? [[String: Any]]
            else {
                continue
            }

            activeSpaceID = currentSpaces["ManagedSpaceID"] as! Int
            totalSpaces = spaces.count
            
            for (index, s) in spaces.enumerated() {
                if (s["ManagedSpaceID"] as! Int) == activeSpaceID {
                    activeSpaceNumber = index + 1
                    break
                }
            }
        }
        
        if let button = statusItem?.button {
            // Clear existing content
            button.title = ""
            button.image = nil
            button.subviews.forEach { $0.removeFromSuperview() }
            
            // Create and configure the indicator view
            if totalSpaces > 0 && activeSpaceNumber > 0 {
                let view = SpaceIndicatorView(activeSpace: activeSpaceNumber, totalSpaces: totalSpaces)
                let hostingView = NSHostingView(rootView: view)
                
                // Calculate width based on content
                let digitWidth: CGFloat = 12  // Width per digit
                let spacing: CGFloat = 6      // Spacing between digits
                let horizontalPadding: CGFloat = 8  // Total horizontal padding
                let width = CGFloat(totalSpaces) * digitWidth +
                          CGFloat(totalSpaces - 1) * spacing +
                          horizontalPadding
                
                // Use button height for consistent vertical sizing
                let height: CGFloat = 22
                
                // Center the view in the button
                hostingView.frame = NSRect(x: 0, y: 0, width: width, height: height)
                
                // Ensure the button is big enough
                button.frame.size.width = width
                
                button.addSubview(hostingView)
            } else {
                // Fallback: show a default icon
                let imageView = NSImageView()
                imageView.image = NSImage(named: NSImage.applicationIconName)
                imageView.frame = NSRect(x: 0, y: 0, width: 22, height: 22)
                imageView.imageScaling = .scaleProportionallyDown
                button.addSubview(imageView)
            }
        }
    }

    @objc func loadWorkspaceFromMenu(_ sender: NSMenuItem) {
        guard let workspace = sender.representedObject as? Workspace else { return }
        launchWorkspaceWithTracking(workspace)
    }

    @objc func deleteWorkspaceFromMenu(_ sender: NSMenuItem) {
        guard let workspace = sender.representedObject as? Workspace else { return }
        var workspaces = loadWorkspaces()
        workspaces.removeAll { $0.id == workspace.id }
        do {
            let url = getWorkspacesURL()
            let data = try JSONEncoder().encode(workspaces)
            try data.write(to: url)
            DispatchQueue.main.async {
                self.populateWorkspacesMenu()
            }
        } catch {
            showErrorAlert(message: "Error deleting workspace: \(error.localizedDescription)")
        }
    }

    func getAppsForCurrentSpace() -> [URL] {
        print("DEBUG: Getting apps for current space...")
        
        // Get all running applications that have visible windows
        let runningApps = NSWorkspace.shared.runningApplications.filter { app in
            guard let bundleId = app.bundleIdentifier else { return false }
            return app.activationPolicy == .regular &&
                   app.isFinishedLaunching &&
                   app.bundleURL != nil &&
                   !bundleId.contains("com.apple.finder") &&
                   !bundleId.contains("NiceUtil")
        }
        
        var appsOnCurrentSpace: [URL] = []
        
        // Get window list for all on-screen windows
        let windowList = CGWindowListCopyWindowInfo([.optionOnScreenOnly, .excludeDesktopElements], kCGNullWindowID) as! [[String: Any]]
        
        for app in runningApps {
            guard let bundleURL = app.bundleURL else { continue }
            let pid = app.processIdentifier
            
            // Check if this app has any visible windows
            let hasVisibleWindows = windowList.contains { window in
                guard let ownerPID = window[kCGWindowOwnerPID as String] as? pid_t,
                      let windowLayer = window[kCGWindowLayer as String] as? Int,
                      let bounds = window[kCGWindowBounds as String] as? [String: Any],
                      let width = bounds["Width"] as? CGFloat,
                      let height = bounds["Height"] as? CGFloat else {
                    return false
                }
                
                // Filter for windows that belong to this app, are on the main window layer,
                // and have reasonable dimensions (not tiny system windows)
                return ownerPID == pid &&
                       windowLayer == 0 &&
                       width > 50 &&
                       height > 50
            }
            
            if hasVisibleWindows {
                print("DEBUG: Found app with visible windows: \(bundleURL.lastPathComponent)")
                appsOnCurrentSpace.append(bundleURL)
            }
        }
        
        print("DEBUG: Found \(appsOnCurrentSpace.count) apps with visible windows on current space")
        
        // If we still don't find any apps, fall back to asking user
        if appsOnCurrentSpace.isEmpty {
            let allRegularApps = runningApps.compactMap { $0.bundleURL }
            if !allRegularApps.isEmpty {
                DispatchQueue.main.async {
                    let alert = NSAlert()
                    alert.messageText = "No windows detected on this space."
                    alert.informativeText = "Would you like to save all currently running apps as this workspace instead?"
                    alert.alertStyle = .warning
                    alert.addButton(withTitle: "Yes")
                    alert.addButton(withTitle: "No")
                    let response = alert.runModal()
                    if response == .alertFirstButtonReturn {
                        self.save(workspaceName: self.pendingWorkspaceName ?? "Workspace", appURLs: allRegularApps)
                        self.pendingWorkspaceName = nil
                    }
                }
            }
            return []
        }
        
        return appsOnCurrentSpace
    }

    // Store the pending workspace name for fallback
    var pendingWorkspaceName: String? = nil

    func save(workspaceName: String, appURLs: [URL]) {
        print("DEBUG: Saving workspace '\(workspaceName)'")
        guard let currentSpace = getCurrentSpaceNumber() else {
            print("DEBUG: Failed to get current space number")
            return
        }
        print("DEBUG: Current space number: \(currentSpace)")
        
        // Create workspace apps with the current space number
        let apps = appURLs.map { url in
            print("DEBUG: Adding app to workspace: \(url.lastPathComponent)")
            return WorkspaceApp(appPath: url.absoluteString, spaceNumber: currentSpace)
        }
        
        let newWorkspace = Workspace(name: workspaceName, apps: apps)
        var workspaces = loadWorkspaces()
        workspaces.append(newWorkspace)
        
        do {
            let url = getWorkspacesURL()
            let data = try JSONEncoder().encode(workspaces)
            try data.write(to: url)
            print("DEBUG: Successfully saved workspace with \(apps.count) apps")
            DispatchQueue.main.async {
                self.populateWorkspacesMenu()
            }
        } catch {
            print("DEBUG: Error saving workspace: \(error)")
            showErrorAlert(message: "Error saving workspaces: \(error.localizedDescription)")
        }
    }

    func getCurrentSpaceNumber() -> Int? {
        print("DEBUG: Getting current space number...")
        let conn = _CGSDefaultConnection()
        let displays = CGSCopyManagedDisplaySpaces(conn) as! [NSDictionary]
        
        for d in displays {
            guard let currentSpaces = d["Current Space"] as? [String: Any],
                  let spaces = d["Spaces"] as? [[String: Any]]
            else { continue }
            
            let activeSpaceID = currentSpaces["ManagedSpaceID"] as! Int
            print("DEBUG: Active space ID: \(activeSpaceID)")
            
            // Find the index of the current space
            for (index, space) in spaces.enumerated() {
                if (space["ManagedSpaceID"] as! Int) == activeSpaceID {
                    let spaceNumber = index + 1
                    print("DEBUG: Mapped to space number: \(spaceNumber)")
                    return spaceNumber
                }
            }
        }
        return nil
    }

    func launchWorkspaceWithTracking(_ workspace: Workspace) {
        print("DEBUG: Launching workspace '\(workspace.name)'")
        var failedApps: [String] = []

        let appsToLaunch = workspace.apps
        print("DEBUG: Found \(appsToLaunch.count) apps to launch")

        for app in appsToLaunch {
            print("DEBUG: Attempting to launch: \(app.appPath) (originally from space \(app.spaceNumber))")
            guard let url = URL(string: app.appPath) else {
                print("DEBUG: Invalid URL: \(app.appPath)")
                failedApps.append(app.appPath)
                continue
            }

            // This configuration ensures that a new window is opened if the app is already running.
            let configuration = NSWorkspace.OpenConfiguration()
            configuration.activates = true
            configuration.createsNewApplicationInstance = true

            NSWorkspace.shared.open(url, configuration: configuration) { runningApp, error in
                if let error = error {
                    print("DEBUG: Failed to process \(url.lastPathComponent): \(error)")
                    failedApps.append(url.lastPathComponent)
                } else {
                    print("DEBUG: Successfully processed \(url.lastPathComponent)")
                }
            }
        }

        if !failedApps.isEmpty {
            DispatchQueue.main.async {
                self.showErrorAlert(message: "Failed to launch: \(failedApps.joined(separator: ", "))")
            }
        }
    }

    @objc func addShortcut(_ sender: NSMenuItem) {
        guard let workspace = sender.representedObject as? Workspace else { return }
        presentShortcutRecorder(for: workspace)
    }

    @objc func editShortcut(_ sender: NSMenuItem) {
        guard let workspace = sender.representedObject as? Workspace else { return }
        presentShortcutRecorder(for: workspace)
    }

    @objc func removeShortcut(_ sender: NSMenuItem) {
        guard let workspace = sender.representedObject as? Workspace else { return }
        let shortcutName = KeyboardShortcuts.Name("workspace_\(workspace.id.uuidString)")
        KeyboardShortcuts.reset(shortcutName)
        DispatchQueue.main.async {
            self.populateWorkspacesMenu()
        }
    }

    func presentShortcutRecorder(for workspace: Workspace) {
        let shortcutView = ShortcutRecorderView(
            workspace: workspace,
            onSave: { [weak self] in
                DispatchQueue.main.async {
                    self?.populateWorkspacesMenu()
                    self?.popover?.performClose(nil)
                }
            },
            onCancel: { [weak self] in
                self?.popover?.performClose(nil)
            }
        )

        let popover = NSPopover()
        popover.contentViewController = NSHostingController(rootView: shortcutView)
        popover.behavior = .transient
        popover.show(relativeTo: self.statusItem!.button!.bounds, of: self.statusItem!.button!, preferredEdge: .minY)
        self.popover = popover
    }

    @objc func saveWorkspace() { 
        let saveView = SaveWorkspaceView(isPresented: .constant(true), onSave: { name in
            self.pendingWorkspaceName = name
            let visibleApps = self.getAppsForCurrentSpace()
            if !visibleApps.isEmpty {
                self.save(workspaceName: name, appURLs: visibleApps)
                self.pendingWorkspaceName = nil
            }
            self.popover?.performClose(nil)
        }, onCancel: {
            self.popover?.performClose(nil)
        })

        let popover = NSPopover()
        popover.contentViewController = NSHostingController(rootView: saveView)
        popover.behavior = .transient
        popover.show(relativeTo: self.statusItem!.button!.bounds, of: self.statusItem!.button!, preferredEdge: .minY)
        self.popover = popover
    }

    func loadWorkspaces() -> [Workspace] {
        do {
            let url = getWorkspacesURL()
            let data = try Data(contentsOf: url)
            let workspaces = try JSONDecoder().decode([Workspace].self, from: data)
            return workspaces
        } catch {
            // If the file doesn't exist or is corrupted, return an empty array
            return []
        }
    }

    func getWorkspacesURL() -> URL {
        let fileManager = FileManager.default
        let appSupportURL = fileManager.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
        let appDirectoryURL = appSupportURL.appendingPathComponent("NiceUtil")

        // Create the directory if it doesn't exist
        if !fileManager.fileExists(atPath: appDirectoryURL.path) {
            try? fileManager.createDirectory(at: appDirectoryURL, withIntermediateDirectories: true, attributes: nil)
        }

        return appDirectoryURL.appendingPathComponent("workspaces.json")
    }

    func getRunningApplications() -> [URL] {
        let runningApps = NSWorkspace.shared.runningApplications
        
        // Filter for regular apps that the user can see and interact with
        let regularApps = runningApps.filter { $0.activationPolicy == .regular && $0.bundleURL != nil }
        
        return regularApps.compactMap { $0.bundleURL }
    }
}
