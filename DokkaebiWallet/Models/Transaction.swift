import Foundation

public enum TransactionType: String, Codable, Sendable, CaseIterable {
    case income, expense, transfer

    public var displayName: String {
        switch self {
        case .income: return "수입"
        case .expense: return "지출"
        case .transfer: return "이체"
        }
    }
}

/// 누구의 돈인가 (PROJECT_PLAN.md D2)
public enum ExpenseScope: String, Codable, Sendable, CaseIterable {
    case shared, personal

    public var displayName: String {
        switch self {
        case .shared: return "공동"
        case .personal: return "개인"
        }
    }
}

/// 누가 볼 수 있나 (PROJECT_PLAN.md D2)
public enum Visibility: String, Codable, Sendable, CaseIterable {
    case family, `private`, selected

    public var displayName: String {
        switch self {
        case .family: return "가족 전체"
        case .private: return "나만 보기"
        case .selected: return "선택한 구성원"
        }
    }
}

public struct LedgerTransaction: Identifiable, Hashable, Codable, Sendable {
    public let id: UUID
    public var type: TransactionType
    /// 원 단위, 항상 양수 (D4)
    public var amount: Int64
    public var occurredAt: Date
    public var categoryID: UUID?
    public var merchant: String?
    public var memo: String?
    public var paymentMethodName: String?
    public var expenseScope: ExpenseScope
    public var visibility: Visibility
    public var createdByID: UUID
    public var spentByID: UUID
    public var hasAttachments: Bool

    public init(id: UUID = UUID(), type: TransactionType, amount: Int64, occurredAt: Date,
                categoryID: UUID?, merchant: String? = nil, memo: String? = nil,
                paymentMethodName: String? = nil, expenseScope: ExpenseScope = .shared,
                visibility: Visibility = .family, createdByID: UUID, spentByID: UUID,
                hasAttachments: Bool = false) {
        self.id = id
        self.type = type
        self.amount = amount
        self.occurredAt = occurredAt
        self.categoryID = categoryID
        self.merchant = merchant
        self.memo = memo
        self.paymentMethodName = paymentMethodName
        self.expenseScope = expenseScope
        // 공동 지출은 반드시 가족 전체 공개 (DB 제약 shared_must_be_family와 동일)
        self.visibility = expenseScope == .shared ? .family : visibility
        self.createdByID = createdByID
        self.spentByID = spentByID
        self.hasAttachments = hasAttachments
    }
}

/// 기간 합계
public struct LedgerSummary: Equatable, Sendable {
    public var income: Int64
    public var expense: Int64
    public var sharedExpense: Int64
    public var personalExpense: Int64

    public init(income: Int64 = 0, expense: Int64 = 0, sharedExpense: Int64 = 0, personalExpense: Int64 = 0) {
        self.income = income
        self.expense = expense
        self.sharedExpense = sharedExpense
        self.personalExpense = personalExpense
    }

    public var balance: Int64 { income - expense }

    /// 이체는 수입·지출 집계에서 제외한다 (FR-HOME-01)
    public init(transactions: [LedgerTransaction]) {
        self.init()
        for transaction in transactions {
            switch transaction.type {
            case .income:
                income += transaction.amount
            case .expense:
                expense += transaction.amount
                if transaction.expenseScope == .shared {
                    sharedExpense += transaction.amount
                } else {
                    personalExpense += transaction.amount
                }
            case .transfer:
                break
            }
        }
    }
}
