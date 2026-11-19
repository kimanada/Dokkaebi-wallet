import Foundation

/// 홈 대시보드 화면 데이터 (FR-HOME-01~07)
public struct HomeDashboard: Sendable {
    public var periodTitle: String
    public var summary: LedgerSummary
    /// 가족 예산 진행 상태 (공동 지출 기준). 예산이 없으면 nil
    public var budget: BudgetStatus?
    public var recentTransactions: [TransactionRowModel]
    public var todayEvents: [CalendarEvent]
    public var upcomingEvents: [CalendarEvent]
    public var pendingTodos: [TodoItem]
    public var pendingTodoCount: Int
    public var myPendingTodoCount: Int
    public var notices: [Notice]
    public var unreadNoticeCount: Int
    public var unreadNotificationCount: Int

    public init(periodTitle: String, summary: LedgerSummary, budget: BudgetStatus?,
                recentTransactions: [TransactionRowModel], todayEvents: [CalendarEvent],
                upcomingEvents: [CalendarEvent], pendingTodos: [TodoItem], pendingTodoCount: Int,
                myPendingTodoCount: Int, notices: [Notice], unreadNoticeCount: Int, unreadNotificationCount: Int) {
        self.periodTitle = periodTitle
        self.summary = summary
        self.budget = budget
        self.recentTransactions = recentTransactions
        self.todayEvents = todayEvents
        self.upcomingEvents = upcomingEvents
        self.pendingTodos = pendingTodos
        self.pendingTodoCount = pendingTodoCount
        self.myPendingTodoCount = myPendingTodoCount
        self.notices = notices
        self.unreadNoticeCount = unreadNoticeCount
        self.unreadNotificationCount = unreadNotificationCount
    }
}
