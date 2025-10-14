import Foundation

struct Match: Codable {
    let id: String
    let user: User
    let matchedAt: Date
    let hasNewMessage: Bool
    let lastMessage: String?
    let lastMessageTime: Date?

    var isActive: Bool {
        return lastMessage != nil
    }
}