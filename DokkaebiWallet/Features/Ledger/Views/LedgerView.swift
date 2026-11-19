import SwiftUI

/// 가계부 탭: 월별 거래 내역 (FR-TX-20~23). 통계·예산은 이후 단계에서 세그먼트로 추가한다.
struct LedgerView: View {
    @Environment(SessionViewModel.self) private var session
    @Environment(AppRouter.self) private var router
    @State private var viewModel: LedgerViewModel

    init(dependencies: AppDependencies) {
        _viewModel = State(initialValue: LedgerViewModel(dependencies: dependencies))
    }

    var body: some View {
        @Bindable var viewModel = viewModel
        ScrollView {
            LazyVStack(alignment: .leading, spacing: DWSpacing.cardGap, pinnedViews: []) {
                GroupSelectorButton()
                if viewModel.isUsingMockData { MockDataBanner() }
                PeriodNavigator(title: viewModel.periodTitle, canGoNext: viewModel.canShowNextPeriod,
                                onPrevious: { Task { await move(-1) } },
                                onNext: { Task { await move(1) } })
                LedgerSummaryCard(summary: viewModel.summary)
                DWSegmentedControl(options: LedgerTypeFilter.allCases, selection: $viewModel.typeFilter) { $0.displayName }
                sections
            }
            .dwScreenPadding()
            .padding(.bottom, DWSpacing.xxl)
        }
        .dwScreenBackground()
        .dwNavigationStyle("가계부")
        .searchable(text: $viewModel.searchText, prompt: "사용처, 메모, 카테고리 검색")
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Menu {
                    Button("카테고리 관리", systemImage: "square.grid.2x2") { router.present(.comingSoon(feature: "카테고리 관리")) }
                    Button("결제수단 관리", systemImage: "creditcard") { router.present(.comingSoon(feature: "결제수단 관리")) }
                    Button("반복 거래", systemImage: "repeat") { router.present(.comingSoon(feature: "반복 거래")) }
                    Button("CSV 가져오기", systemImage: "square.and.arrow.down") { router.present(.comingSoon(feature: "CSV 가져오기")) }
                } label: {
                    Image(systemName: "ellipsis.circle")
                }
                .accessibilityLabel("가계부 메뉴")
            }
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    router.present(.comingSoon(feature: "거래 등록"))
                } label: {
                    Image(systemName: "plus.circle.fill")
                }
                .accessibilityLabel("거래 추가")
                .accessibilityIdentifier("ledger.add")
            }
        }
        .refreshable { await reload() }
        .task(id: session.groupRevision) { await reload(resetPeriod: true) }
        .accessibilityIdentifier("screen.ledger")
    }

    @ViewBuilder
    private var sections: some View {
        DWStateView(state: viewModel.state, retry: { Task { await reload() } }) {
            DWEmptyState(systemImage: "list.bullet.rectangle",
                         title: viewModel.searchText.isEmpty ? "이 기간에는 기록이 없어요" : "검색 결과가 없어요",
                         message: viewModel.searchText.isEmpty ? "거래를 기록하면 날짜별로 정리해 드릴게요" : "다른 검색어로 찾아보세요")
                .dwCardBackground()
        } content: { sections in
            ForEach(sections) { section in
                DaySectionCard(section: section) { router.push(.transactionDetail($0)) }
            }
        }
    }

    private func reload(resetPeriod: Bool = false) async {
        guard let group = session.currentGroup else { return }
        await viewModel.load(group: group, members: session.members, resetPeriod: resetPeriod)
    }

    private func move(_ direction: Int) async {
        guard let group = session.currentGroup else { return }
        if direction < 0 {
            await viewModel.showPreviousPeriod(group: group, members: session.members)
        } else {
            await viewModel.showNextPeriod(group: group, members: session.members)
        }
    }
}

/// ‹ 2026년 11월 › 기간 이동
struct PeriodNavigator: View {
    let title: String
    var canGoNext = true
    let onPrevious: () -> Void
    let onNext: () -> Void

    var body: some View {
        HStack {
            Button(action: onPrevious) {
                Image(systemName: "chevron.left").frame(width: DWSpacing.minTouchTarget, height: DWSpacing.minTouchTarget)
            }
            .accessibilityLabel("이전 기간")
            Spacer()
            Text(title).dwFont(.title3).accessibilityAddTraits(.isHeader)
            Spacer()
            Button(action: onNext) {
                Image(systemName: "chevron.right").frame(width: DWSpacing.minTouchTarget, height: DWSpacing.minTouchTarget)
            }
            .disabled(!canGoNext)
            .accessibilityLabel("다음 기간")
        }
        .font(.body.weight(.semibold))
        .foregroundStyle(DWColor.primary)
    }
}

private struct LedgerSummaryCard: View {
    let summary: LedgerSummary

    var body: some View {
        HStack(spacing: 0) {
            item("수입", MoneyFormatter.won(summary.income, sign: .plus), DWColor.income)
            Divider().frame(height: 32).overlay(DWColor.border)
            item("지출", MoneyFormatter.won(summary.expense), DWColor.textPrimary)
            Divider().frame(height: 32).overlay(DWColor.border)
            item("합계", MoneyFormatter.won(summary.balance), summary.balance >= 0 ? DWColor.textPrimary : DWColor.danger)
        }
        .padding(.vertical, DWSpacing.lg)
        .dwCardBackground()
    }

    private func item(_ title: String, _ value: String, _ color: Color) -> some View {
        VStack(spacing: DWSpacing.xs) {
            Text(title).dwFont(.caption, color: DWColor.textSecondary)
            Text(value)
                .font(DWTypography.amountRow.font)
                .foregroundStyle(color)
                .lineLimit(1)
                .minimumScaleFactor(0.6)
        }
        .frame(maxWidth: .infinity)
        .padding(.horizontal, DWSpacing.xs)
        .accessibilityElement(children: .combine)
    }
}

private struct DaySectionCard: View {
    let section: TransactionDaySection
    let onSelect: (TransactionRowModel) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: DWSpacing.sm) {
            HStack {
                Text(section.title).dwFont(.subheadline, color: DWColor.textSecondary).fontWeight(.semibold)
                Spacer()
                if section.summary.income > 0 {
                    Text(MoneyFormatter.won(section.summary.income, sign: .plus))
                        .font(DWTypography.footnote.font.monospacedDigit())
                        .foregroundStyle(DWColor.income)
                }
                if section.summary.expense > 0 {
                    Text(MoneyFormatter.won(section.summary.expense))
                        .font(DWTypography.footnote.font.monospacedDigit())
                        .foregroundStyle(DWColor.textSecondary)
                }
            }
            .accessibilityElement(children: .combine)
            .padding(.horizontal, DWSpacing.xs)

            VStack(spacing: 0) {
                ForEach(section.rows) { row in
                    Button { onSelect(row) } label: { TransactionRowView(row: row, showsTime: true) }
                        .buttonStyle(.plain)
                    if row.id != section.rows.last?.id {
                        Divider().overlay(DWColor.border).padding(.leading, 48)
                    }
                }
            }
            .padding(.horizontal, DWSpacing.lg)
            .padding(.vertical, DWSpacing.sm)
            .dwCardBackground()
        }
    }
}

#Preview("가계부") {
    PreviewHost { LedgerView(dependencies: $0.dependencies) }
}
