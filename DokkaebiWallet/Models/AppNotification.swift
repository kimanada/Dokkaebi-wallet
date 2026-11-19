import Foundation

public enum AppNotificationType: String, Codable, Sendable {
    case transactionCreated = "transaction_created"
    case noticeCreated = "notice_created"
    case eventCreated = "event_created"
    case eventUpdated = "event_updated"
    case taskAssigned = "task_assigned"
    case taskDueSoon = "task_due_soon"
    case budgetWarning = "budget_warning"
    case budgetExceeded = "budget_exceeded"
    case memberJoined = "member_joined"

    /// SF Symbol
    public var icon: String {
        switch self {
        case .transactionCreated: return "wonsign.circle"
        case .noticeCreated: return "megaphone"
        case .eventCreated, .eventUpdated: return "calendar"
        case .taskAssigned, .taskDueSoon: return "checklist"
        case .budgetWarning, .budgetExceeded: return "exclamationmark.triangle"
        case .memberJoined: return "person.badge.plus"
        }
    }
}

public struct AppNotification: Identifiable, Hashable, Codable, Sendable {
    public let id: UUID
    public var type: AppNotificationType
    public var title: String
    public var body: String
    public var createdAt: Date
    public var isRead: Bool

    public init(id: UUID = UUID(), type: AppNotificationType, title: String, body: String,
                createdAt: Date, isRead: Bool = false) {
        self.id = id
        self.type = type
        self.title = title
        self.body = body
        self.createdAt = createdAt
        self.isRead = isRead
    }
}
