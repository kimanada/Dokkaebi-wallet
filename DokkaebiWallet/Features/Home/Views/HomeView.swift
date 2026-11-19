import SwiftUI

/// 홈 대시보드 (FR-HOME, DESIGN_SYSTEM.md §8 화면 구성)
struct HomeView: View {
    @Environment(SessionViewModel.self) private var session
    @Environment(AppRouter.self) private var router
    @State private var viewModel: HomeViewModel

    init(dependencies: AppDependencies) {
        _viewModel = State(initialValue: HomeViewModel(dependencies: dependencies))
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: DWSpacing.cardGap) {
                HomeHeader(unreadCount: viewModel.state.value?.unreadNotificationCount ?? 0) {
                    router.push(.notifications)
                }
                GroupSelectorButton()
                if viewModel.isUsingMockData {
                    MockDataBanner()
                }
                content
            }
            .dwScreenPadding()
            .padding(.bottom, DWSpacing.xxl)
        }
        .dwScreenBackground()
        .toolbar(.hidden, for: .navigationBar)
        .refreshable { await reload() }
        .task(id: session.groupRevision) { await reload() }
        .accessibilityIdentifier("screen.home")
    }

    @ViewBuilder
    private var content: some View {
        switch viewModel.state {
        case .idle, .loading:
            DWSkeletonCard(lines: 4)
            DWSkeletonCard()
            DWSkeletonCard()
        case .failed(let error):
            DWErrorView(error: error) { Task { await reload() } }
                .dwCardBackground()
        case .empty:
            DWEmptyState(title: "표시할 내용이 없어요").dwCardBackground()
        case .loaded(let dashboard):
            MonthlySummaryCard(dashboard: dashboard)
            BudgetCard(budget: dashboard.budget) {
                router.present(.comingSoon(feature: "예산 설정"))
            }
            RecentTransactionsCard(rows: dashboard.recentTransactions) { row in
                router.push(.transactionDetail(row))
            } onMore: {
                router.select(.ledger)
            }
            TodayScheduleCard(today: dashboard.todayEvents, upcoming: dashboard.upcomingEvents) {
                router.select(.calendar)
            }
            TodoSummaryCard(dashboard: dashboard) {
                router.open(.todos, in: .more)
            }
            NoticeSummaryCard(notices: dashboard.notices, unreadCount: dashboard.unreadNoticeCount) { notice in
                router.push(.noticeDetail(notice))
            } onMore: {
                router.open(.notices, in: .more)
            }
        }
    }

    private func reload() async {
        guard let group = session.currentGroup else { return }
        await viewModel.load(group: group, members: session.members)
    }
}

// MARK: - 헤더

/// 로고와 서비스명, 알림 버튼
private struct HomeHeader: View {
    let unreadCount: Int
    let onNotifications: () -> Void

    var body: some View {
        HStack {
            DWLogo()
            Spacer()
            DWIconButton(systemImage: "bell", accessibilityLabel: "알림 센터", badgeCount: unreadCount,
                         action: onNotifications)
        }
        .padding(.top, DWSpacing.sm)
    }
}

/// 가족 그룹 선택 영역 (FR-GRP-02)
struct GroupSelectorButton: View {
    @Environment(SessionViewModel.self) private var session
    @Environment(AppRouter.self) private var router

    var body: some View {
        Button {
            router.present(.groupSwitcher)
        } label: {
            HStack(spacing: DWSpacing.md) {
                Image(systemName: "house.fill")
                    .foregroundStyle(DWColor.primary)
                    .frame(width: 36, height: 36)
                    .background(DWColor.primarySoft, in: Circle())
                VStack(alignment: .leading, spacing: 2) {
                    Text("현재 가족").dwFont(.caption, color: DWColor.textTertiary)
                    HStack(spacing: DWSpacing.xs) {
                        Text(session.currentGroup?.name ?? "가족 선택").dwFont(.headline)
                        Image(systemName: "chevron.down")
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(DWColor.textSecondary)
                    }
                }
                Spacer()
                DWAvatarStack(members: session.members, size: 26)
            }
            .padding(.horizontal, DWSpacing.lg)
            .padding(.vertical, DWSpacing.md)
            .dwCardBackground(radius: DWRadius.lg)
        }
        .buttonStyle(.plain)
        .accessibilityLabel("현재 가족 \(session.currentGroup?.name ?? ""), 구성원 \(session.members.count)명")
        .accessibilityHint("눌러서 다른 가족 그룹으로 전환")
        .accessibilityIdentifier("home.groupSelector")
    }
}

// MARK: - 이번 달 요약

private struct MonthlySummaryCard: View {
    let dashboard: HomeDashboard

    var body: some View {
        let summary = dashboard.summary
        DWCard {
            VStack(alignment: .leading, spacing: DWSpacing.lg) {
                VStack(alignment: .leading, spacing: DWSpacing.xs) {
                    Text("\(dashboard.periodTitle) 지출").dwFont(.subheadline, color: DWColor.textSecondary)
                    Text(MoneyFormatter.won(summary.expense))
                        .font(DWTypography.display.font)
                        .foregroundStyle(DWColor.textPrimary)
                        .minimumScaleFactor(0.6)
                        .lineLimit(1)
                }
                .accessibilityElement(children: .combine)

                HStack(spacing: DWSpacing.md) {
                    SummaryTile(title: "수입", amount: MoneyFormatter.won(summary.income, sign: .plus),
                                color: DWColor.income, systemImage: "arrow.down.left")
                    SummaryTile(title: "남은 돈", amount: MoneyFormatter.won(summary.balance),
                                color: summary.balance >= 0 ? DWColor.textPrimary : DWColor.danger,
                                systemImage: "equal")
                }

                Divider().overlay(DWColor.border)

                // 공동 지출 vs 개인 지출 (FR-HOME-03)
                VStack(alignment: .leading, spacing: DWSpacing.sm) {
                    Text("공동 지출과 개인 지출").dwFont(.footnote, color: DWColor.textSecondary)
                    SharedPersonalBar(shared: summary.sharedExpense, personal: summary.personalExpense)
                    HStack {
                        LegendItem(color: DWColor.primary, title: "공동", amount: summary.sharedExpense)
                        Spacer()
                        LegendItem(color: DWColor.brown, title: "개인", amount: summary.personalExpense)
                    }
                }
            }
        }
        .accessibilityIdentifier("home.summary")
    }
}

private struct SummaryTile: View {
    let title: String
    let amount: String
    let color: Color
    let systemImage: String

    var body: some View {
        VStack(alignment: .leading, spacing: DWSpacing.xs) {
            Label(title, systemImage: systemImage)
                .labelStyle(.titleAndIcon)
                .dwFont(.caption, color: DWColor.textSecondary)
            Text(amount)
                .font(DWTypography.amountRow.font)
                .foregroundStyle(color)
                .lineLimit(1)
                .minimumScaleFactor(0.7)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(DWSpacing.md)
        .background(DWColor.subtle, in: RoundedRectangle.dw(DWRadius.md))
        .accessibilityElement(children: .combine)
    }
}

private struct SharedPersonalBar: View {
    let shared: Int64
    let personal: Int64

    var body: some View {
        GeometryReader { proxy in
            let total = max(shared + personal, 1)
            let sharedWidth = proxy.size.width * CGFloat(shared) / CGFloat(total)
            HStack(spacing: 2) {
                Capsule().fill(DWColor.primary).frame(width: max(sharedWidth - 1, 0))
                Capsule().fill(DWColor.brown)
            }
        }
        .frame(height: 10)
        .accessibilityHidden(true)
    }
}

private struct LegendItem: View {
    let color: Color
    let title: String
    let amount: Int64

    var body: some View {
        HStack(spacing: DWSpacing.xs + 2) {
            Circle().fill(color).frame(width: 8, height: 8)
            Text(title).dwFont(.footnote, color: DWColor.textSecondary)
            Text(MoneyFormatter.won(amount)).font(DWTypography.footnote.font.monospacedDigit().weight(.semibold))
                .foregroundStyle(DWColor.textPrimary)
        }
        .accessibilityElement(children: .combine)
    }
}

// MARK: - 예산

private struct BudgetCard: View {
    let budget: BudgetStatus?
    let onSetup: () -> Void

    var body: some View {
        DWCard(title: "가족 예산", subtitle: "공동 지출 기준") {
            if let budget {
                VStack(alignment: .leading, spacing: DWSpacing.md) {
                    HStack(alignment: .firstTextBaseline) {
                        Text(budget.remaining >= 0 ? "남은 예산" : "초과 금액")
                            .dwFont(.subheadline, color: DWColor.textSecondary)
                        Spacer()
                        Text(MoneyFormatter.won(abs(budget.remaining)))
                            .font(DWTypography.title3.font.monospacedDigit())
                            .foregroundStyle(budget.level == .exceeded ? DWColor.danger : DWColor.textPrimary)
                    }
                    DWProgressBar(progress: budget.progress, tint: budget.level.color)
                    HStack {
                        Text("\(budget.percent)% 사용")
                            .dwFont(.footnote, color: budget.level == .normal ? DWColor.textSecondary : budget.level.color)
                            .fontWeight(budget.level == .normal ? .regular : .semibold)
                        Spacer()
                        Text("\(MoneyFormatter.won(budget.spentAmount)) / \(MoneyFormatter.won(budget.budgetAmount))")
                            .font(DWTypography.footnote.font.monospacedDigit())
                            .foregroundStyle(DWColor.textSecondary)
                    }
                }
                .accessibilityElement(children: .combine)
            } else {
                DWEmptyState(systemImage: "chart.pie", title: "이번 달 예산이 없어요",
                             message: "예산을 정하면 남은 금액을 알려드릴게요",
                             actionTitle: "예산 설정하기", action: onSetup)
            }
        }
        .accessibilityIdentifier("home.budget")
    }
}

// MARK: - 최근 거래

private struct RecentTransactionsCard: View {
    let rows: [TransactionRowModel]
    let onSelect: (TransactionRowModel) -> Void
    let onMore: () -> Void

    var body: some View {
        DWCard(title: "최근 거래", actionTitle: "전체 보기", action: onMore) {
            if rows.isEmpty {
                DWEmptyState(systemImage: "list.bullet.rectangle", title: "아직 이번 달 기록이 없어요")
            } else {
                VStack(spacing: 0) {
                    ForEach(rows) { row in
                        Button { onSelect(row) } label: { TransactionRowView(row: row) }
                            .buttonStyle(.plain)
                        if row.id != rows.last?.id {
                            Divider().overlay(DWColor.border).padding(.leading, 48)
                        }
                    }
                }
            }
        }
        .accessibilityIdentifier("home.recentTransactions")
    }
}

// MARK: - 일정

private struct TodayScheduleCard: View {
    let today: [CalendarEvent]
    let upcoming: [CalendarEvent]
    let onMore: () -> Void
    private let formatting = DateFormatting()

    var body: some View {
        DWCard(title: "오늘의 일정", actionTitle: "캘린더", action: onMore) {
            VStack(alignment: .leading, spacing: DWSpacing.md) {
                if today.isEmpty {
                    Text("오늘은 여유로운 하루예요").dwFont(.subheadline, color: DWColor.textSecondary)
                } else {
                    ForEach(today) { EventRow(event: $0, timeText: timeText(for: $0)) }
                }
                if !upcoming.isEmpty {
                    Divider().overlay(DWColor.border)
                    Text("이번 주").dwFont(.caption, color: DWColor.textTertiary)
                    ForEach(upcoming.prefix(3)) { event in
                        EventRow(event: event, timeText: formatting.shortDate(event.startsAt) +
                                 (event.isAllDay ? " 종일" : " " + formatting.time(event.startsAt)))
                    }
                }
            }
        }
        .accessibilityIdentifier("home.schedule")
    }

    private func timeText(for event: CalendarEvent) -> String {
        event.isAllDay ? "종일" : formatting.time(event.startsAt)
    }
}

struct EventRow: View {
    let event: CalendarEvent
    let timeText: String

    var body: some View {
        HStack(spacing: DWSpacing.md) {
            RoundedRectangle.dw(2)
                .fill(Color(palette: event.color))
                .frame(width: 4, height: 36)
            VStack(alignment: .leading, spacing: 2) {
                Text(event.title).dwFont(.headline).lineLimit(1)
                Text([timeText, event.location].compactMap { $0 }.joined(separator: " · "))
                    .dwFont(.footnote, color: DWColor.textSecondary)
                    .lineLimit(1)
            }
            Spacer(minLength: 0)
            VisibilityBadge(visibility: event.visibility)
        }
        .accessibilityElement(children: .combine)
    }
}

// MARK: - 할 일

private struct TodoSummaryCard: View {
    let dashboard: HomeDashboard
    let onMore: () -> Void
    private let formatting = DateFormatting()

    var body: some View {
        DWCard(title: "할 일", subtitle: "미완료 \(dashboard.pendingTodoCount)개 · 내 할 일 \(dashboard.myPendingTodoCount)개",
               actionTitle: "전체 보기", action: onMore) {
            if dashboard.pendingTodos.isEmpty {
                Text("모두 끝냈어요!").dwFont(.subheadline, color: DWColor.textSecondary)
            } else {
                VStack(alignment: .leading, spacing: DWSpacing.md) {
                    ForEach(dashboard.pendingTodos.prefix(3)) { todo in
                        HStack(spacing: DWSpacing.md) {
                            Image(systemName: todo.status == .inProgress ? "circle.lefthalf.filled" : "circle")
                                .foregroundStyle(todo.priority == .urgent ? DWColor.danger : DWColor.textTertiary)
                                .accessibilityHidden(true)
                            Text(todo.title).dwFont(.body).lineLimit(1)
                            Spacer()
                            if let due = todo.dueDate {
                                let label = formatting.dDay(due)
                                DueTag(text: label, isUrgent: label == "D-Day" || label.hasPrefix("D+"))
                            }
                        }
                        .accessibilityElement(children: .combine)
                    }
                }
            }
        }
        .accessibilityIdentifier("home.todos")
    }
}

struct DueTag: View {
    let text: String
    var isUrgent = false

    var body: some View {
        DWTag(title: text,
              foreground: isUrgent ? DWColor.danger : DWColor.textSecondary,
              background: isUrgent ? DWColor.danger.opacity(0.12) : DWColor.subtle)
    }
}

// MARK: - 공지

private struct NoticeSummaryCard: View {
    let notices: [Notice]
    let unreadCount: Int
    let onSelect: (Notice) -> Void
    let onMore: () -> Void

    var body: some View {
        DWCard(title: "공지사항", subtitle: unreadCount > 0 ? "읽지 않은 공지 \(unreadCount)개" : nil,
               actionTitle: "전체 보기", action: onMore) {
            if notices.isEmpty {
                Text("가족에게 전할 소식을 남겨 보세요").dwFont(.subheadline, color: DWColor.textSecondary)
            } else {
                VStack(spacing: DWSpacing.sm) {
                    ForEach(notices) { notice in
                        Button { onSelect(notice) } label: { NoticeRowView(notice: notice, compact: true) }
                            .buttonStyle(.plain)
                    }
                }
            }
        }
        .accessibilityIdentifier("home.notices")
    }
}

#Preview("홈") {
    PreviewHost { HomeView(dependencies: $0.dependencies) }
}
