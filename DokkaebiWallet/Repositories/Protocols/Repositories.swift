import Foundation

// MARK: - Repository 프로토콜
// ViewModel은 이 프로토콜에만 의존한다. 현재는 Mock 구현을 주입하고,
// 이후 단계에서 Supabase + 로컬 캐시 구현으로 교체한다 (APP_STRUCTURE.md §1).

public protocol FamilyRepository: Sendable {
    func fetchGroups() async throws -> [FamilyGroup]
    func fetchMembers(groupID: UUID) async throws -> [FamilyMember]
}

public protocol TransactionRepository: Sendable {
    func fetchTransactions(groupID: UUID, period: BudgetPeriod) async throws -> [LedgerTransaction]
    func fetchCategories(groupID: UUID) async throws -> [LedgerCategory]
}

public protocol BudgetRepository: Sendable {
    /// 가족 예산 (공동 지출만 집계, PROJECT_PLAN.md D6)
    func fetchFamilyBudget(groupID: UUID, period: BudgetPeriod) async throws -> Budget?
}

public protocol CalendarRepository: Sendable {
    func fetchEvents(groupID: UUID, from: Date, to: Date) async throws -> [CalendarEvent]
}

public protocol NoticeRepository: Sendable {
    func fetchNotices(groupID: UUID) async throws -> [Notice]
}

public protocol TodoRepository: Sendable {
    func fetchTodos(groupID: UUID) async throws -> [TodoItem]
    func updateStatus(todoID: UUID, status: TodoStatus) async throws -> TodoItem
}

public protocol WalletRepository: Sendable {
    /// 개인 카드 + 현재 그룹의 공유 카드
    func fetchCards(groupID: UUID) async throws -> [WalletCard]
    func setFavorite(cardID: UUID, isFavorite: Bool) async throws
}

public protocol NotificationRepository: Sendable {
    func fetchNotifications() async throws -> [AppNotification]
    func markAsRead(ids: [UUID]) async throws
    func delete(id: UUID) async throws
}
