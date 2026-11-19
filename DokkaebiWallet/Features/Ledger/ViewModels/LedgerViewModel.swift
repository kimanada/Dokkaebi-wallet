import Foundation
import Observation

public struct TransactionDaySection: Identifiable, Sendable {
    public let date: Date
    public let title: String
    public let rows: [TransactionRowModel]
    public let summary: LedgerSummary
    public var id: Date { date }
}

public enum LedgerTypeFilter: String, CaseIterable, Sendable {
    case all, expense, income, transfer

    public var displayName: String {
        switch self {
        case .all: return "전체"
        case .expense: return "지출"
        case .income: return "수입"
        case .transfer: return "이체"
        }
    }

    func matches(_ type: TransactionType) -> Bool {
        switch self {
        case .all: return true
        case .expense: return type == .expense
        case .income: return type == .income
        case .transfer: return type == .transfer
        }
    }
}

@MainActor
@Observable
public final class LedgerViewModel {
    public private(set) var state: ViewState<[TransactionDaySection]> = .idle
    public private(set) var summary = LedgerSummary()
    public private(set) var period: BudgetPeriod
    public var typeFilter: LedgerTypeFilter = .all { didSet { rebuild() } }
    public var searchText: String = "" { didSet { rebuild() } }

    private var rows: [TransactionRowModel] = []
    private let dependencies: AppDependencies
    private let now: @Sendable () -> Date
    private var monthStartDay = 1

    public init(dependencies: AppDependencies, now: @escaping @Sendable () -> Date = { Date() }) {
        self.dependencies = dependencies
        self.now = now
        self.period = BudgetPeriod.containing(now(), monthStartDay: 1, calendar: dependencies.dateFormatting.calendar)
    }

    public var isUsingMockData: Bool { dependencies.isUsingMockData }
    public var periodTitle: String { dependencies.dateFormatting.monthTitle(period.start) }

    /// 다음 달은 오늘이 속한 기간까지만 이동할 수 있다.
    public var canShowNextPeriod: Bool { !period.contains(now()) && period.start < now() }

    private var calendar: Calendar { dependencies.dateFormatting.calendar }

    public func load(group: FamilyGroup, members: [FamilyMember], resetPeriod: Bool = false) async {
        if resetPeriod || group.monthStartDay != monthStartDay {
            monthStartDay = group.monthStartDay
            period = BudgetPeriod.containing(now(), monthStartDay: monthStartDay, calendar: calendar)
        }
        if rows.isEmpty { state = .loading }
        do {
            async let transactions = dependencies.transactions.fetchTransactions(groupID: group.id, period: period)
            async let categories = dependencies.transactions.fetchCategories(groupID: group.id)
            let txs = try await transactions
            summary = LedgerSummary(transactions: txs)
            rows = TransactionRowModel.make(txs, categories: try await categories, members: members)
            rebuild()
        } catch {
            state = .failed(.wrap(error))
        }
    }

    public func showPreviousPeriod(group: FamilyGroup, members: [FamilyMember]) async {
        period = period.previous(calendar: calendar)
        rows = []
        await load(group: group, members: members)
    }

    public func showNextPeriod(group: FamilyGroup, members: [FamilyMember]) async {
        guard canShowNextPeriod else { return }
        period = BudgetPeriod.containing(period.endExclusive, monthStartDay: monthStartDay, calendar: calendar)
        rows = []
        await load(group: group, members: members)
    }

    private func rebuild() {
        let keyword = searchText.trimmingCharacters(in: .whitespaces)
        let filtered = rows.filter { row in
            guard typeFilter.matches(row.transaction.type) else { return false }
            guard !keyword.isEmpty else { return true }
            return [row.transaction.merchant, row.transaction.memo, row.category?.name]
                .compactMap { $0 }
                .contains { $0.localizedCaseInsensitiveContains(keyword) }
        }
        guard !filtered.isEmpty else {
            state = .empty
            return
        }
        let grouped = Dictionary(grouping: filtered) { calendar.startOfDay(for: $0.transaction.occurredAt) }
        let formatting = dependencies.dateFormatting
        state = .loaded(grouped.keys.sorted(by: >).map { day in
            let dayRows = (grouped[day] ?? []).sorted { $0.transaction.occurredAt > $1.transaction.occurredAt }
            return TransactionDaySection(date: day, title: formatting.dayLabel(day, relativeTo: now()),
                                         rows: dayRows, summary: LedgerSummary(transactions: dayRows.map(\.transaction)))
        })
    }
}
