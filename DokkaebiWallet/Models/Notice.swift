import Foundation

public struct Notice: Identifiable, Hashable, Codable, Sendable {
    public let id: UUID
    public var title: String
    public var body: String
    public var authorID: UUID
    public var createdAt: Date
    public var isPinned: Bool
    public var readCount: Int
    public var memberCount: Int
    public var isReadByMe: Bool

    public init(id: UUID = UUID(), title: String, body: String, authorID: UUID, createdAt: Date,
                isPinned: Bool = false, readCount: Int, memberCount: Int, isReadByMe: Bool) {
        self.id = id
        self.title = title
        self.body = body
        self.authorID = authorID
        self.createdAt = createdAt
        self.isPinned = isPinned
        self.readCount = readCount
        self.memberCount = memberCount
        self.isReadByMe = isReadByMe
    }
}
