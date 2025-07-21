import Foundation

struct WorkspaceApp: Codable, Equatable {
    var appPath: String
    var spaceNumber: Int
}

struct Workspace: Codable, Identifiable, Equatable {
    var id: UUID
    var name: String
    var apps: [WorkspaceApp]
    
    init(id: UUID = UUID(), name: String, apps: [WorkspaceApp]) {
        self.id = id
        self.name = name
        self.apps = apps
    }
    
    static func == (lhs: Workspace, rhs: Workspace) -> Bool {
        lhs.id == rhs.id
    }
}
