import Foundation
import Observation

public enum WalletFilter: String, CaseIterable, Sendable {
    case all, personal, family

    public var displayName: String {
        switch self {
        case .all: return "전체"
        case .personal: return "개인"
        case .family: return "가족 공유"
        }
    }
}

@MainActor
@Observable
public final class WalletViewModel {
    public private(set) var state: ViewState<[WalletCard]> = .idle
    public var filter: WalletFilter = .all { didSet { rebuild() } }
    public var searchText: String = "" { didSet { rebuild() } }

    private var cards: [WalletCard] = []
    private let repository: any WalletRepository
    private let mock: Bool

    public init(dependencies: AppDependencies) {
        self.repository = dependencies.wallet
        self.mock = dependencies.isUsingMockData
    }

    public var isUsingMockData: Bool { mock }
    public var allCards: [WalletCard] { cards }

    public func load(groupID: UUID) async {
        if cards.isEmpty { state = .loading }
        do {
            cards = try await repository.fetchCards(groupID: groupID)
            rebuild()
        } catch {
            state = .failed(.wrap(error))
        }
    }

    public func toggleFavorite(_ card: WalletCard) async {
        guard let index = cards.firstIndex(where: { $0.id == card.id }) else { return }
        let newValue = !cards[index].isFavorite
        cards[index].isFavorite = newValue  // 낙관적 업데이트
        rebuild()
        do {
            try await repository.setFavorite(cardID: card.id, isFavorite: newValue)
        } catch {
            cards[index].isFavorite = !newValue
            rebuild()
        }
    }

    /// 즐겨찾기 → 이름순 (FR-WAL-06)
    private func rebuild() {
        let keyword = searchText.trimmingCharacters(in: .whitespaces)
        let visible = cards
            .filter { card in
                switch filter {
                case .all: return true
                case .personal: return card.scope == .personal
                case .family: return card.scope == .family
                }
            }
            .filter { card in
                keyword.isEmpty || [card.brandName, card.cardName, card.memo]
                    .compactMap { $0 }
                    .contains { $0.localizedCaseInsensitiveContains(keyword) }
            }
            .sorted {
                if $0.isFavorite != $1.isFavorite { return $0.isFavorite }
                return $0.brandName.localizedCompare($1.brandName) == .orderedAscending
            }
        state = visible.isEmpty ? .empty : .loaded(visible)
    }
}
