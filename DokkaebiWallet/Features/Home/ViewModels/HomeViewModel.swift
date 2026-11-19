import Foundation
import Observation

@MainActor
@Observable
public final class HomeViewModel {
    public private(set) var state: ViewState<HomeDashboard> = .idle

    private let dependencies: AppDependencies
    private let now: @Sendable () -> Date

    public init(dependencies: AppDependencies, now: @escaping @Sendable () -> Date = { Date() }) {
        self.dependencies = dependencies
        self.now = now
    }

    public var isUsingMockData: Bool { dependencies.isUsingMockData }

    public func load(group: FamilyGroup, members: [FamilyMember]) async {
        if state.value == nil { state = .loading }
        let formatting = dependencies.dateFormatting
        let calendar = formatting.calendar
        let today = now()
        let period = BudgetPeriod.containing(today, monthStartDay: group.monthStartDay, calendar: calendar)
        let startOfToday = calendar.startOfDay(for: today)
        let startOfTomorrow = calendar.date(byAdding: .day, value: 1, to: startOfToday) ?? startOfToday
        let weekEnd = calendar.date(byAdding: .day, value: 7, to: startOfToday) ?? startOfToday
        let meID = members.first(where: \.isMe)?.id

        do {
            async let transactions = dependencies.transactions.fetchTransactions(groupID: group.id, period: period)
            async let categories = dependencies.transactions.fetchCategories(groupID: group.id)
            async let budget = dependencies.budgets.fetchFamilyBudget(groupID: group.id, period: period)
            async let events = dependencies.calendar.fetchEvents(groupID: group.id, from: startOfToday, to: weekEnd)
            async let todos = dependencies.todos.fetchTodos(groupID: group.id)
            async let notices = dependencies.notices.fetchNotices(groupID: group.id)
            async let notifications = dependencies.notifications.fetchNotifications()

            let txs = try await transactions
            let summary = LedgerSummary(transactions: txs)
            let budgetStatus = try await budget.map {
                BudgetStatus(budgetAmount: $0.totalAmount, spentAmount: summary.sharedExpense,
                             warnThresholdPercent: $0.warnThresholdPercent)
            }
            let allEvents = try await events
            let allTodos = try await todos
            let pending = meID.map { allTodos.pendingSorted(for: $0) } ?? allTodos.filter { !$0.isDone }
            let allNotices = try await notices

            state = .loaded(HomeDashboard(
                periodTitle: formatting.monthTitle(period.start),
                summary: summary,
                budget: budgetStatus,
                recentTransactions: Array(TransactionRowModel.make(txs, categories: try await categories,
                                                                   members: members).prefix(5)),
                todayEvents: allEvents.filter { $0.occurs(on: today, calendar: calendar) },
                upcomingEvents: Array(allEvents.filter { $0.startsAt >= startOfTomorrow }.prefix(5)),
                pendingTodos: Array(pending.prefix(5)),
                pendingTodoCount: pending.count,
                myPendingTodoCount: meID.map { id in pending.filter { $0.assigneeIDs.contains(id) }.count } ?? 0,
                notices: Array(allNotices.prefix(3)),
                unreadNoticeCount: allNotices.filter { !$0.isReadByMe }.count,
                unreadNotificationCount: try await notifications.filter { !$0.isRead }.count
            ))
        } catch {
            state = .failed(.wrap(error))
        }
    }
}
