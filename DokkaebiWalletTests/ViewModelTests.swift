import Foundation
import Testing
@testable import DokkaebiWallet

@MainActor
@Suite("ViewModel")
struct ViewModelTests {
    let data = Fixture.mockData()

    private func loadedSession(_ dependencies: AppDependencies) async -> SessionViewModel {
        let session = SessionViewModel(repository: dependencies.family)
        await session.load()
        return session
    }

    @Test("세션: 첫 그룹 선택, 그룹 전환 시 revision 증가")
    func session() async throws {
        let session = await loadedSession(Fixture.dependencies(data: data))
        #expect(session.currentGroup?.id == MockData.homeGroupID)
        #expect(session.me?.isMe == true)
        let revision = session.groupRevision
        let other = try #require(session.groups.last)
        await session.select(other)
        #expect(session.currentGroup?.id == other.id)
        #expect(session.groupRevision == revision + 1)
        await session.select(other)  // 같은 그룹은 무시
        #expect(session.groupRevision == revision + 1)
    }

    @Test("세션: 불러오기 실패 시 오류 보관")
    func sessionFailure() async {
        let session = await loadedSession(Fixture.dependencies(data: data, behavior: .offline))
        #expect(session.currentGroup == nil)
        #expect(session.loadError == .network(.offline))
    }

    @Test("홈: 이번 달 합계, 예산(공동 지출 기준), 목록 개수 제한")
    func home() async throws {
        let dependencies = Fixture.dependencies(data: data)
        let session = await loadedSession(dependencies)
        let viewModel = HomeViewModel(dependencies: dependencies, now: { Fixture.now })
        await viewModel.load(group: try #require(session.currentGroup), members: session.members)
        let dashboard = try #require(viewModel.state.value)

        let monthly = data.transactions.filter {
            BudgetPeriod.containing(Fixture.now, monthStartDay: 1, calendar: Fixture.calendar).contains($0.occurredAt)
        }
        let expected = LedgerSummary(transactions: monthly)
        #expect(dashboard.summary == expected)
        #expect(dashboard.periodTitle == "2026년 11월")
        #expect(dashboard.budget?.spentAmount == expected.sharedExpense)
        #expect(dashboard.recentTransactions.count == 5)
        #expect(dashboard.todayEvents.map(\.title) == ["하늘이 학부모 상담", "가족 저녁 식사"])
        #expect(dashboard.upcomingEvents.allSatisfy { $0.startsAt >= Fixture.calendar.startOfDay(for: Fixture.date(2026, 11, 20)) })
        #expect(dashboard.pendingTodos.count <= 5)
        #expect(dashboard.pendingTodoCount == 5)
        #expect(dashboard.notices.first?.isPinned == true)
        #expect(dashboard.unreadNoticeCount == 1)
        #expect(dashboard.unreadNotificationCount == 2)
    }

    @Test("홈: 오류 상태")
    func homeFailure() async {
        let viewModel = HomeViewModel(dependencies: Fixture.dependencies(data: data, behavior: .offline), now: { Fixture.now })
        await viewModel.load(group: data.groups[0], members: data.members)
        #expect(viewModel.state.error == .network(.offline))
    }

    @Test("가계부: 날짜별 묶음, 유형 필터, 검색, 이전 달 빈 상태")
    func ledger() async throws {
        let dependencies = Fixture.dependencies(data: data)
        let session = await loadedSession(dependencies)
        let group = try #require(session.currentGroup)
        let viewModel = LedgerViewModel(dependencies: dependencies, now: { Fixture.now })
        await viewModel.load(group: group, members: session.members)

        let sections = try #require(viewModel.state.value)
        #expect(sections.first?.title == "11월 19일 (목)")
        #expect(sections.map(\.date) == sections.map(\.date).sorted(by: >))
        #expect(!viewModel.canShowNextPeriod)

        viewModel.typeFilter = .income
        let incomeRows = try #require(viewModel.state.value).flatMap(\.rows)
        #expect(!incomeRows.isEmpty)
        #expect(incomeRows.allSatisfy { $0.transaction.type == .income })

        viewModel.typeFilter = .all
        viewModel.searchText = "마트"
        #expect(try #require(viewModel.state.value).flatMap(\.rows).map(\.title) == ["초록마트"])

        viewModel.searchText = "존재하지 않는 검색어"
        if case .empty = viewModel.state {} else { Issue.record("검색 결과가 없으면 빈 상태여야 한다") }

        viewModel.searchText = ""
        await viewModel.showPreviousPeriod(group: group, members: session.members)
        #expect(viewModel.periodTitle == "2026년 10월")
        #expect(viewModel.canShowNextPeriod)
    }

    @Test("지갑: 즐겨찾기 우선 정렬, 필터, 즐겨찾기 토글")
    func wallet() async throws {
        let viewModel = WalletViewModel(dependencies: Fixture.dependencies(data: data))
        await viewModel.load(groupID: MockData.homeGroupID)
        let cards = try #require(viewModel.state.value)
        let favoriteFlags = cards.map(\.isFavorite)
        #expect(favoriteFlags == favoriteFlags.sorted { $0 && !$1 })

        viewModel.filter = .personal
        #expect(try #require(viewModel.state.value).allSatisfy { $0.scope == .personal })

        viewModel.filter = .all
        let target = try #require(cards.last)
        await viewModel.toggleFavorite(target)
        #expect(viewModel.allCards.first { $0.id == target.id }?.isFavorite == !target.isFavorite)
    }

    @Test("캘린더: 42칸 격자, 오늘 표시, 월 이동")
    func calendar() async {
        let viewModel = CalendarViewModel(dependencies: Fixture.dependencies(data: data), now: { Fixture.now })
        await viewModel.load(groupID: MockData.homeGroupID)
        let grid = viewModel.monthGrid
        #expect(grid.count == 42)
        #expect(grid.first?.isSunday == true)
        #expect(grid.filter(\.isToday).count == 1)
        #expect(grid.first { $0.isToday }?.eventColors.count == 2)
        #expect(viewModel.eventsOnSelectedDate.count == 2)
        #expect(viewModel.weekDays.count == 7)

        viewModel.move(by: 1)
        #expect(viewModel.title == "2026년 12월")
        viewModel.goToToday()
        #expect(viewModel.title == "2026년 11월")

        viewModel.mode = .day
        viewModel.move(by: 1)
        #expect(viewModel.title == "11월 20일 (금)")
    }

    @Test("할 일: 내 할 일 필터와 완료 토글")
    func todos() async throws {
        let dependencies = Fixture.dependencies(data: data)
        let viewModel = TodoViewModel(dependencies: dependencies)
        await viewModel.load(groupID: MockData.homeGroupID, meID: data.me.id)
        let mine = try #require(viewModel.state.value)
        #expect(mine.allSatisfy { $0.assigneeIDs.contains(data.me.id) && !$0.isDone })

        let first = try #require(mine.first)
        await viewModel.toggleDone(first)
        #expect(viewModel.state.value?.contains { $0.id == first.id } != true)
        viewModel.filter = .done
        #expect(try #require(viewModel.state.value).contains { $0.id == first.id })
    }

    @Test("알림: 읽음 처리와 삭제")
    func notifications() async throws {
        let viewModel = NotificationViewModel(dependencies: Fixture.dependencies(data: data))
        await viewModel.load()
        #expect(viewModel.unreadCount == 2)
        await viewModel.markAllAsRead()
        #expect(viewModel.unreadCount == 0)
        let first = try #require(viewModel.state.value?.first)
        await viewModel.delete(first)
        #expect(viewModel.state.value?.contains { $0.id == first.id } == false)
    }
}

@MainActor
@Suite("라우터 AppRouter")
struct AppRouterTests {
    @Test("같은 탭을 다시 누르면 첫 화면으로")
    func reselectPopsToRoot() {
        let router = AppRouter()
        router.push(.notices)
        router.push(.todos)
        #expect(router.path(for: .home).count == 2)
        router.select(.home)
        #expect(router.path(for: .home).isEmpty)
    }

    @Test("다른 탭에서 화면 열기")
    func openInTab() {
        let router = AppRouter()
        router.open(.notices, in: .more)
        #expect(router.selectedTab == .more)
        #expect(router.path(for: .more) == [.notices])
        router.select(.home)
        #expect(router.selectedTab == .home)
        #expect(router.path(for: .more) == [.notices])
    }

    @Test("탭 5개 순서")
    func tabs() {
        #expect(AppTab.allCases.map(\.title) == ["홈", "가계부", "지갑", "캘린더", "전체"])
    }
}
