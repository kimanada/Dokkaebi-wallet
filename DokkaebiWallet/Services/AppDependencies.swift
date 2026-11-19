import Foundation

/// 의존성 묶음 (APP_STRUCTURE.md §3). ViewModel은 여기서 Repository 프로토콜을 받는다.
public struct AppDependencies: Sendable {
    public let configuration: AppConfiguration
    public let family: any FamilyRepository
    public let transactions: any TransactionRepository
    public let budgets: any BudgetRepository
    public let calendar: any CalendarRepository
    public let notices: any NoticeRepository
    public let todos: any TodoRepository
    public let wallet: any WalletRepository
    public let notifications: any NotificationRepository
    public let dateFormatting: DateFormatting

    public var isUsingMockData: Bool { configuration.dataSourceMode == .mock }

    public init(configuration: AppConfiguration,
                family: any FamilyRepository,
                transactions: any TransactionRepository,
                budgets: any BudgetRepository,
                calendar: any CalendarRepository,
                notices: any NoticeRepository,
                todos: any TodoRepository,
                wallet: any WalletRepository,
                notifications: any NotificationRepository,
                dateFormatting: DateFormatting = DateFormatting()) {
        self.configuration = configuration
        self.family = family
        self.transactions = transactions
        self.budgets = budgets
        self.calendar = calendar
        self.notices = notices
        self.todos = todos
        self.wallet = wallet
        self.notifications = notifications
        self.dateFormatting = dateFormatting
    }

    /// Mock 데이터로 구성한 의존성
    public static func mock(data: MockData = MockData(), behavior: MockBehavior = .instant,
                            configuration: AppConfiguration? = nil) -> AppDependencies {
        AppDependencies(
            configuration: configuration ?? AppConfiguration(environmentName: "Mock", supabaseURL: nil,
                                                             supabaseAnonKey: nil, dataSourceMode: .mock),
            family: MockFamilyRepository(data: data, behavior: behavior),
            transactions: MockTransactionRepository(data: data, behavior: behavior),
            budgets: MockBudgetRepository(data: data, behavior: behavior),
            calendar: MockCalendarRepository(data: data, behavior: behavior),
            notices: MockNoticeRepository(data: data, behavior: behavior),
            todos: MockTodoRepository(data: data, behavior: behavior),
            wallet: MockWalletRepository(data: data, behavior: behavior),
            notifications: MockNotificationRepository(data: data, behavior: behavior),
            dateFormatting: DateFormatting(timeZone: data.calendar.timeZone)
        )
    }
}
