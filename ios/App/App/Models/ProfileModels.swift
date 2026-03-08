import Foundation

struct UserProfile: Codable, Identifiable {
    var id: String
    var fullName: String?
    var updatedAt: String?

    enum CodingKeys: String, CodingKey {
        case id
        case fullName = "full_name"
        case updatedAt = "updated_at"
    }
}

struct Child: Codable, Identifiable {
    var id: String
    var parentId: String
    var fullName: String
    var dateOfBirth: String?
    var gender: String?
    var position: String?
    var notes: String?
    var createdAt: String?

    enum CodingKeys: String, CodingKey {
        case id
        case parentId = "parent_id"
        case fullName = "full_name"
        case dateOfBirth = "date_of_birth"
        case gender, position, notes
        case createdAt = "created_at"
    }

    static let positions = ["Pitcher", "Catcher", "1B", "2B", "3B", "SS", "LF", "CF", "RF"]
    static let genders = ["Male", "Female", "Other", "Prefer not to say"]
}
