import Foundation
import Supabase

@MainActor
class ProfileViewModel: ObservableObject {
    @Published var profile: UserProfile?
    @Published var children: [Child] = []
    @Published var isLoading = false
    @Published var error: String?

    private let supabase = SupabaseService.shared

    func load(userId: String) async {
        isLoading = true
        defer { isLoading = false }
        do {
            async let p = supabase.fetchProfile(userId: userId)
            async let c = supabase.fetchChildren(parentId: userId)
            (profile, children) = try await (p, c)
        } catch {
            self.error = error.localizedDescription
        }
    }

    func updateName(_ name: String, userId: String) async throws {
        var p = profile ?? UserProfile(id: userId, fullName: name)
        p.fullName = name
        try await supabase.upsertProfile(p)
        profile = p
    }

    func addChild(_ child: Child) async throws {
        try await supabase.insertChild(child)
        children.append(child)
    }

    func updateChild(_ child: Child) async throws {
        try await supabase.updateChild(child)
        if let idx = children.firstIndex(where: { $0.id == child.id }) {
            children[idx] = child
        }
    }

    func deleteChild(id: String) async throws {
        try await supabase.deleteChild(id: id)
        children.removeAll { $0.id == id }
    }
}
