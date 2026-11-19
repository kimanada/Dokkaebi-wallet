import SwiftUI

/// 하단 탭 5개 (홈 / 가계부 / 지갑 / 캘린더 / 전체). 탭마다 독립된 NavigationStack을 가진다.
struct MainTabView: View {
    @Environment(AppRouter.self) private var router

    var body: some View {
        // 이미 선택된 탭을 다시 누르면 첫 화면으로 돌아가도록 선택 바인딩을 감싼다.
        let selection = Binding<AppTab>(get: { router.selectedTab }, set: { router.select($0) })

        TabView(selection: selection) {
            ForEach(AppTab.allCases, id: \.self) { tab in
                TabStack(tab: tab)
                    .tabItem { Label(tab.title, systemImage: tab.systemImage) }
                    .tag(tab)
            }
        }
        .sheet(item: Binding(get: { router.sheet }, set: { router.sheet = $0 })) { sheet in
            switch sheet {
            case .groupSwitcher:
                GroupSwitcherSheet()
                    .presentationDetents([.medium, .large])
            case .comingSoon(let feature):
                ComingSoonSheet(feature: feature)
                    .presentationDetents([.medium])
            }
        }
        .fullScreenCover(item: Binding(get: { router.fullScreen }, set: { router.fullScreen = $0 })) { cover in
            switch cover {
            case .barcode(let card):
                BarcodeFullScreenView(card: card)
            }
        }
    }
}

/// 탭 하나의 NavigationStack
private struct TabStack: View {
    let tab: AppTab
    @Environment(AppContainer.self) private var container
    @Environment(AppRouter.self) private var router

    var body: some View {
        let path = Binding<[AppRoute]>(get: { router.path(for: tab) }, set: { router.setPath($0, for: tab) })
        NavigationStack(path: path) {
            root
                .navigationDestination(for: AppRoute.self) { route in
                    AppRouteDestination(route: route)
                }
        }
    }

    @ViewBuilder
    private var root: some View {
        let dependencies = container.dependencies
        switch tab {
        case .home: HomeView(dependencies: dependencies)
        case .ledger: LedgerView(dependencies: dependencies)
        case .wallet: WalletView(dependencies: dependencies)
        case .calendar: CalendarView(dependencies: dependencies)
        case .more: MoreMenuView()
        }
    }
}

/// push 화면 목적지
struct AppRouteDestination: View {
    let route: AppRoute
    @Environment(AppContainer.self) private var container

    var body: some View {
        let dependencies = container.dependencies
        switch route {
        case .transactionDetail(let row): TransactionDetailView(row: row)
        case .notices: NoticeListView(dependencies: dependencies)
        case .noticeDetail(let notice): NoticeDetailView(notice: notice)
        case .todos: TodoListView(dependencies: dependencies)
        case .notifications: NotificationListView(dependencies: dependencies)
        case .family: FamilyView()
        case .settings: SettingsView()
        case .designSystemGallery: DesignSystemGalleryView()
        }
    }
}

#Preview("메인 탭") {
    MainTabPreview()
}

/// 그룹을 불러온 상태의 미리보기
struct MainTabPreview: View {
    @State private var container = AppContainer.preview()

    var body: some View {
        Group {
            if container.session.currentGroup != nil {
                MainTabView()
            } else {
                ProgressView()
            }
        }
        .environment(container)
        .environment(container.session)
        .environment(container.router)
        .task { await container.session.load() }
    }
}
