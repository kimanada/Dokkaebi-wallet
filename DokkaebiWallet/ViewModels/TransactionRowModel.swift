import Foundation

/// 거래 목록 한 줄에 필요한 표시 정보 (홈과 가계부가 함께 쓴다)
public struct TransactionRowModel: Identifiable, Hashable, Sendable {
    public let transaction: LedgerTransaction
    public let category: LedgerCategory?
    public let spender: FamilyMember?

    public init(transaction: LedgerTransaction, category: LedgerCategory?, spender: FamilyMember?) {
        self.transaction = transaction
        self.category = category
        self.spender = spender
    }

    public var id: UUID { transaction.id }

    public var title: String {
        transaction.merchant ?? category?.name ?? transaction.type.displayName
    }

    /// 카테고리 · 결제수단
    public var subtitle: String {
        [transaction.type == .transfer ? "이체" : category?.name, transaction.paymentMethodName]
            .compactMap { $0 }
            .joined(separator: " · ")
    }

    /// 수입은 "+", 지출은 부호 없음 (DESIGN_SYSTEM.md §3)
    public var amountText: String {
        MoneyFormatter.won(transaction.amount, sign: transaction.type == .income ? .plus : .none)
    }

    public var icon: String {
        if transaction.type == .transfer { return "arrow.left.arrow.right" }
        return category?.icon ?? "questionmark.circle"
    }

    public var color: PaletteColor {
        transaction.type == .transfer ? .ink : (category?.color ?? .sand)
    }

    public static func make(_ transactions: [LedgerTransaction], categories: [LedgerCategory],
                            members: [FamilyMember]) -> [TransactionRowModel] {
        let categoryByID = Dictionary(uniqueKeysWithValues: categories.map { ($0.id, $0) })
        let memberByID = Dictionary(uniqueKeysWithValues: members.map { ($0.id, $0) })
        return transactions.map { transaction in
            TransactionRowModel(transaction: transaction,
                                category: transaction.categoryID.flatMap { categoryByID[$0] },
                                spender: memberByID[transaction.spentByID])
        }
    }
}

extension AppError {
    /// 임의의 오류를 AppError로 변환한다.
    public static func wrap(_ error: Error) -> AppError {
        (error as? AppError) ?? .unknown(description: String(describing: error))
    }
}
