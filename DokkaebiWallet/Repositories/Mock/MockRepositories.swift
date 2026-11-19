import Foundation

// MARK: - Mock 구현
// 실제 데이터가 연결되기 전까지 사용하는 임시 저장소. 모든 화면은 이 데이터에
// "샘플 데이터" 표시를 붙여 실제 데이터가 아님을 알린다.

public struct MockFamilyRepository: FamilyRepository {
    let data: MockData
    let behavior: MockBehavior

    public init(data: MockData, behavior: MockBehavior = .instant) {
        self.data = data
        self.behavior = behavior
    }

    public func fetchGroups() async throws -> [FamilyGroup] {
        try await behavior.perform()
        return data.groups
    }

    public func fetchMembers(groupID: UUID) async throws -> [FamilyMember] {
        try await behavior.perform()
        return data.members
    }
}

public struct MockTransactionRepository: TransactionRepository {
    let data: MockData
    let behavior: MockBehavior

    public init(data: MockData, behavior: MockBehavior = .instant) {
        self.data = data
        self.behavior = behavior
    }

    public func fetchTransactions(groupID: UUID, period: BudgetPeriod) async throws -> [LedgerTransaction] {
        try await behavior.perform()
        return data.transactions
            .filter { period.contains($0.occurredAt) }
            .sorted { $0.occurredAt > $1.occurredAt }
    }

    public func fetchCategories(groupID: UUID) async throws -> [LedgerCategory] {
        try await behavior.perform()
        return data.categories.sorted { $0.sortOrder < $1.sortOrder }
    }
}

public struct MockBudgetRepository: BudgetRepository {
    let data: MockData
    let behavior: MockBehavior

    public init(data: MockData, behavior: MockBehavior = .instant) {
        self.data = data
        self.behavior = behavior
    }

    public func fetchFamilyBudget(groupID: UUID, period: BudgetPeriod) async throws -> Budget? {
        try await behavior.perform()
        return data.budget
    }
}

public struct MockCalendarRepository: CalendarRepository {
    let data: MockData
    let behavior: MockBehavior

    public init(data: MockData, behavior: MockBehavior = .instant) {
        self.data = data
        self.behavior = behavior
    }

    public func fetchEvents(groupID: UUID, from: Date, to: Date) async throws -> [CalendarEvent] {
        try await behavior.perform()
        return data.events
            .filter { $0.startsAt < to && $0.endsAt >= from }
            .sorted { $0.startsAt < $1.startsAt }
    }
}

public struct MockNoticeRepository: NoticeRepository {
    let data: MockData
    let behavior: MockBehavior

    public init(data: MockData, behavior: MockBehavior = .instant) {
        self.data = data
        self.behavior = behavior
    }

    public func fetchNotices(groupID: UUID) async throws -> [Notice] {
        try await behavior.perform()
        // 고정 공지 먼저, 그다음 최신순
        return data.notices.sorted {
            if $0.isPinned != $1.isPinned { return $0.isPinned }
            return $0.createdAt > $1.createdAt
        }
    }
}

public actor MockTodoRepository: TodoRepository {
    private var todos: [TodoItem]
    private let behavior: MockBehavior

    public init(data: MockData, behavior: MockBehavior = .instant) {
        self.todos = data.todos
        self.behavior = behavior
    }

    public func fetchTodos(groupID: UUID) async throws -> [TodoItem] {
        try await behavior.perform()
        return todos
    }

    public func updateStatus(todoID: UUID, status: TodoStatus) async throws -> TodoItem {
        try await behavior.perform()
        guard let index = todos.firstIndex(where: { $0.id == todoID }) else { throw AppError.notFound }
        todos[index].status = status
        return todos[index]
    }
}

public actor MockWalletRepository: WalletRepository {
    private var cards: [WalletCard]
    private let behavior: MockBehavior

    public init(data: MockData, behavior: MockBehavior = .instant) {
        self.cards = data.cards
        self.behavior = behavior
    }

    public func fetchCards(groupID: UUID) async throws -> [WalletCard] {
        try await behavior.perform()
        return cards
    }

    public func setFavorite(cardID: UUID, isFavorite: Bool) async throws {
        try await behavior.perform()
        guard let index = cards.firstIndex(where: { $0.id == cardID }) else { throw AppError.notFound }
        cards[index].isFavorite = isFavorite
    }
}

public actor MockNotificationRepository: NotificationRepository {
    private var items: [AppNotification]
    private let behavior: MockBehavior

    public init(data: MockData, behavior: MockBehavior = .instant) {
        self.items = data.notifications
        self.behavior = behavior
    }

    public func fetchNotifications() async throws -> [AppNotification] {
        try await behavior.perform()
        return items.sorted { $0.createdAt > $1.createdAt }
    }

    public func markAsRead(ids: [UUID]) async throws {
        try await behavior.perform()
        for index in items.indices where ids.contains(items[index].id) {
            items[index].isRead = true
        }
    }

    public func delete(id: UUID) async throws {
        try await behavior.perform()
        items.removeAll { $0.id == id }
    }
}
