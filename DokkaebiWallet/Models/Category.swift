import Foundation

public enum CategoryKind: String, Codable, Sendable {
    case income, expense
}

/// 가족 그룹 단위 통합 카테고리 (PROJECT_PLAN.md D12)
public struct LedgerCategory: Identifiable, Hashable, Codable, Sendable {
    public let id: UUID
    public var kind: CategoryKind
    public var name: String
    /// SF Symbol 이름
    public var icon: String
    public var color: PaletteColor
    public var sortOrder: Int
    public var isActive: Bool

    public init(id: UUID = UUID(), kind: CategoryKind, name: String, icon: String,
                color: PaletteColor, sortOrder: Int = 0, isActive: Bool = true) {
        self.id = id
        self.kind = kind
        self.name = name
        self.icon = icon
        self.color = color
        self.sortOrder = sortOrder
        self.isActive = isActive
    }
}
