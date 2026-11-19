import Foundation

public enum BudgetScope: String, Codable, Sendable {
    case family, personal
}

public struct Budget: Identifiable, Hashable, Codable, Sendable {
    public let id: UUID
    public var scope: BudgetScope
    public var totalAmount: Int64
    public var warnThresholdPercent: Int

    public init(id: UUID = UUID(), scope: BudgetScope, totalAmount: Int64, warnThresholdPercent: Int = 80) {
        self.id = id
        self.scope = scope
        self.totalAmount = totalAmount
        self.warnThresholdPercent = warnThresholdPercent
    }
}

/// 예산 진행 상태 (FR-HOME-02, FR-BUD)
public struct BudgetStatus: Equatable, Sendable {
    public enum Level: Equatable, Sendable {
        case normal, warning, exceeded
    }

    public let budgetAmount: Int64
    public let spentAmount: Int64
    public let warnThresholdPercent: Int

    public init(budgetAmount: Int64, spentAmount: Int64, warnThresholdPercent: Int = 80) {
        self.budgetAmount = budgetAmount
        self.spentAmount = spentAmount
        self.warnThresholdPercent = warnThresholdPercent
    }

    public var remaining: Int64 { budgetAmount - spentAmount }

    /// 0.0 ~ (초과 시 1.0 이상)
    public var progress: Double {
        guard budgetAmount > 0 else { return 0 }
        return Double(spentAmount) / Double(budgetAmount)
    }

    public var percent: Int { Int((progress * 100).rounded(.down)) }

    public var level: Level {
        if spentAmount > budgetAmount { return .exceeded }
        if percent >= warnThresholdPercent { return .warning }
        return .normal
    }
}
