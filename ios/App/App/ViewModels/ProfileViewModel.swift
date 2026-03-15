import Foundation

@MainActor
class ProfileViewModel: ObservableObject {
    @Published var profile: UserProfile?
    @Published var children: [Child] = []
    @Published var isLoading = false
    @Published var error: String?

    private let service = SupabaseService.shared

    func load(userId: String) async {
        isLoading = true
        defer { isLoading = false }
        do {
            async let p = service.fetchProfile(userId: userId)
            async let c = service.fetchChildren(parentId: userId)
            (profile, children) = try await (p, c)
        } catch {
            self.error = error.localizedDescription
        }
    }

    func updateName(_ name: String, userId: String) async throws {
        var p = profile ?? UserProfile(id: userId, fullName: name)
        p.fullName = name
        try await service.upsertProfile(p)
        profile = p
    }

    func addChild(_ child: Child) async throws {
        try await service.insertChild(child)
        children.append(child)
    }

    func updateChild(_ child: Child) async throws {
        try await service.updateChild(child)
        if let idx = children.firstIndex(where: { $0.id == child.id }) {
            children[idx] = child
        }
    }

    func deleteChild(id: String) async throws {
        try await service.deleteChild(id: id)
        children.removeAll { $0.id == id }
    }
}
