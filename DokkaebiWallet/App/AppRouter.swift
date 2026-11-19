import Foundation
import Observation

/// 하단 탭 (APP_STRUCTURE.md §5.1)
public enum AppTab: String, CaseIterable, Hashable, Sendable {
    case home, ledger, wallet, calendar, more

    public var title: String {
        switch self {
        case .home: return "홈"
        case .ledger: return "가계부"
        case .wallet: return "지갑"
        case .calendar: return "캘린더"
        case .more: return "전체"
        }
    }

    /// SF Symbol (선택 시 `.fill` 변형은 TabView가 자동 적용)
    public var systemImage: String {
        switch self {
        case .home: return "house"
        case .ledger: return "list.bullet.rectangle"
        case .wallet: return "wallet.pass"
        case .calendar: return "calendar"
        case .more: return "square.grid.2x2"
        }
    }
}

/// 스택 안에서 이동하는 화면 (push)
public enum AppRoute: Hashable, Sendable {
    case transactionDetail(TransactionRowModel)
    case notices
    case noticeDetail(Notice)
    case todos
    case notifications
    case family
    case settings
    case designSystemGallery
}

/// 모달 시트
public enum AppSheet: Identifiable, Hashable, Sendable {
    case groupSwitcher
    /// 아직 구현되지 않은 기능 안내
    case comingSoon(feature: String)

    public var id: String {
        switch self {
        case .groupSwitcher: return "groupSwitcher"
        case .comingSoon(let feature): return "comingSoon.\(feature)"
        }
    }
}

/// 전체 화면 모달
public enum AppFullScreen: Identifiable, Hashable, Sendable {
    case barcode(WalletCard)

    public var id: String {
        switch self {
        case .barcode(let card): return "barcode.\(card.id)"
        }
    }
}

/// 탭별 NavigationStack 경로와 모달 상태를 관리한다 (APP_STRUCTURE.md §5.2).
@MainActor
@Observable
public final class AppRouter {
    public var selectedTab: AppTab = .home
    public var paths: [AppTab: [AppRoute]] = Dictionary(uniqueKeysWithValues: AppTab.allCases.map { ($0, []) })
    public var sheet: AppSheet?
    public var fullScreen: AppFullScreen?

    public init() {}

    public func path(for tab: AppTab) -> [AppRoute] {
        paths[tab] ?? []
    }

    public func setPath(_ path: [AppRoute], for tab: AppTab) {
        paths[tab] = path
    }

    /// 현재 탭 스택에 화면을 쌓는다.
    public func push(_ route: AppRoute) {
        paths[selectedTab, default: []].append(route)
    }

    /// 다른 탭으로 이동한 뒤 화면을 쌓는다. 예: 홈의 "공지 더보기" → 전체 탭 > 공지사항
    public func open(_ route: AppRoute, in tab: AppTab) {
        selectedTab = tab
        paths[tab] = [route]
    }

    /// 탭을 선택한다. 이미 선택된 탭을 다시 누르면 첫 화면으로 돌아간다.
    public func select(_ tab: AppTab) {
        if tab == selectedTab {
            paths[tab] = []
        } else {
            selectedTab = tab
        }
    }

    public func present(_ sheet: AppSheet) {
        self.sheet = sheet
    }

    public func present(_ fullScreen: AppFullScreen) {
        self.fullScreen = fullScreen
    }
}
