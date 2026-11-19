import Foundation

public enum TodoStatus: String, Codable, Sendable, CaseIterable {
    case todo, inProgress = "in_progress", done

    public var displayName: String {
        switch self {
        case .todo: return "예정"
        case .inProgress: return "진행 중"
        case .done: return "완료"
        }
    }
}

public enum TodoPriority: String, Codable, Sendable, CaseIterable, Comparable {
    case low, normal, high, urgent

    public var displayName: String {
        switch self {
        case .low: return "낮음"
        case .normal: return "보통"
        case .high: return "높음"
        case .urgent: return "긴급"
        }
    }

    private var rank: Int {
        switch self {
        case .low: return 0
        case .normal: return 1
        case .high: return 2
        case .urgent: return 3
        }
    }

    public static func < (lhs: TodoPriority, rhs: TodoPriority) -> Bool { lhs.rank < rhs.rank }
}

public struct TodoItem: Identifiable, Hashable, Codable, Sendable {
    public let id: UUID
    public var title: String
    public var status: TodoStatus
    public var priority: TodoPriority
    public var dueDate: Date?
    public var assigneeIDs: [UUID]

    public init(id: UUID = UUID(), title: String, status: TodoStatus = .todo, priority: TodoPriority = .normal,
                dueDate: Date? = nil, assigneeIDs: [UUID] = []) {
        self.id = id
        self.title = title
        self.status = status
        self.priority = priority
        self.dueDate = dueDate
        self.assigneeIDs = assigneeIDs
    }

    public var isDone: Bool { status == .done }
}

extension Array where Element == TodoItem {
    /// 미완료 항목을 나에게 배정된 것 먼저, 그다음 마감이 가까운 순으로 정렬한다 (FR-HOME-06)
    public func pendingSorted(for userID: UUID) -> [TodoItem] {
        filter { !$0.isDone }.sorted { lhs, rhs in
            let lhsMine = lhs.assigneeIDs.contains(userID)
            let rhsMine = rhs.assigneeIDs.contains(userID)
            if lhsMine != rhsMine { return lhsMine }
            switch (lhs.dueDate, rhs.dueDate) {
            case let (l?, r?) where l != r: return l < r
            case (.some, .none): return true
            case (.none, .some): return false
            default: return lhs.priority > rhs.priority
            }
        }
    }
}
