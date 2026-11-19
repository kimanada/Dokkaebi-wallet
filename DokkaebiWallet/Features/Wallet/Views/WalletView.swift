import SwiftUI

/// 지갑 탭: 멤버십 바코드·QR 카드 목록 (FR-WAL-04, 06)
struct WalletView: View {
    @Environment(SessionViewModel.self) private var session
    @Environment(AppRouter.self) private var router
    @State private var viewModel: WalletViewModel
    @State private var addOptions: DWConfirmationState?

    init(dependencies: AppDependencies) {
        _viewModel = State(initialValue: WalletViewModel(dependencies: dependencies))
    }

    var body: some View {
        @Bindable var viewModel = viewModel
        ScrollView {
            VStack(alignment: .leading, spacing: DWSpacing.cardGap) {
                if viewModel.isUsingMockData {
                    MockDataBanner(message: "샘플 카드예요. 실제 카드 등록과 오프라인 저장은 다음 단계에서 연결돼요")
                }
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: DWSpacing.sm) {
                        ForEach(WalletFilter.allCases, id: \.self) { filter in
                            DWChip(title: filter.displayName, isSelected: viewModel.filter == filter) {
                                withAnimation(DWMotion.quick) { viewModel.filter = filter }
                            }
                        }
                    }
                }
                DWStateView(state: viewModel.state, retry: { Task { await reload() } }) {
                    DWEmptyState(systemImage: "wallet.pass", title: "자주 쓰는 멤버십을 담아 두세요",
                                 message: viewModel.searchText.isEmpty ? "바코드를 스캔하거나 직접 입력할 수 있어요" : "검색 결과가 없어요",
                                 actionTitle: "카드 추가") { showAddOptions() }
                        .dwCardBackground()
                } content: { cards in
                    LazyVStack(spacing: DWSpacing.lg) {
                        ForEach(cards) { card in
                            WalletCardView(card: card) {
                                Task { await viewModel.toggleFavorite(card) }
                            }
                            .onTapGesture { router.present(.barcode(card)) }
                            .accessibilityAddTraits(.isButton)
                            .accessibilityHint("눌러서 바코드를 전체 화면으로 보기")
                        }
                    }
                }
            }
            .dwScreenPadding()
            .padding(.bottom, DWSpacing.xxl)
        }
        .dwScreenBackground()
        .dwNavigationStyle("지갑")
        .searchable(text: $viewModel.searchText, prompt: "브랜드, 카드명, 메모 검색")
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button { showAddOptions() } label: { Image(systemName: "plus.circle.fill") }
                    .accessibilityLabel("카드 추가")
            }
        }
        .dwConfirmationDialog($addOptions)
        .refreshable { await reload() }
        .task(id: session.groupRevision) { await reload() }
        .accessibilityIdentifier("screen.wallet")
    }

    private func reload() async {
        guard let group = session.currentGroup else { return }
        await viewModel.load(groupID: group.id)
    }

    private func showAddOptions() {
        addOptions = DWConfirmationState(title: "카드 추가 방법", options: [
            .init(title: "카메라로 스캔") { router.present(.comingSoon(feature: "바코드 스캔")) },
            .init(title: "사진에서 가져오기") { router.present(.comingSoon(feature: "사진에서 바코드 인식")) },
            .init(title: "직접 입력") { router.present(.comingSoon(feature: "카드 직접 입력")) }
        ])
    }
}

/// 지갑 카드 (신용카드 비율 1.586:1)
struct WalletCardView: View {
    let card: WalletCard
    var onToggleFavorite: (() -> Void)?

    var body: some View {
        ZStack(alignment: .topLeading) {
            RoundedRectangle.dw(DWRadius.xl)
                .fill(LinearGradient(colors: [Color(palette: card.color), Color(palette: card.color).opacity(0.82)],
                                     startPoint: .topLeading, endPoint: .bottomTrailing))
            LuckyDotPattern(dotSize: 7, spacing: 10)
                .foregroundStyle(.white.opacity(0.12))
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottomTrailing)
                .padding(DWSpacing.xl)

            VStack(alignment: .leading, spacing: DWSpacing.xs) {
                HStack(alignment: .top) {
                    VStack(alignment: .leading, spacing: 2) {
                        Text(card.brandName).font(.system(.title3, weight: .bold))
                        if let cardName = card.cardName {
                            Text(cardName).font(.subheadline).opacity(0.85)
                        }
                    }
                    Spacer()
                    if let onToggleFavorite {
                        Button(action: onToggleFavorite) {
                            Image(systemName: card.isFavorite ? "star.fill" : "star")
                                .font(.title3)
                                .foregroundStyle(card.isFavorite ? DWColor.gold : .white.opacity(0.8))
                                .frame(width: DWSpacing.minTouchTarget, height: DWSpacing.minTouchTarget)
                        }
                        .buttonStyle(.plain)
                        .accessibilityLabel(card.isFavorite ? "즐겨찾기 해제" : "즐겨찾기")
                    }
                }
                Spacer()
                HStack(alignment: .bottom) {
                    VStack(alignment: .leading, spacing: 2) {
                        if let number = card.formattedNumber {
                            Text(number).font(.system(.callout, design: .monospaced, weight: .medium))
                        }
                        Text(card.barcodeType.displayName).font(.caption).opacity(0.75)
                    }
                    Spacer()
                    Label(card.scope.displayName, systemImage: card.scope == .family ? "person.2.fill" : "person.fill")
                        .font(.caption.weight(.semibold))
                        .padding(.horizontal, DWSpacing.sm)
                        .padding(.vertical, DWSpacing.xs)
                        .background(.white.opacity(0.18), in: Capsule())
                }
            }
            .foregroundStyle(.white)
            .padding(DWSpacing.xl)
        }
        .aspectRatio(1.586, contentMode: .fit)
        .dwShadow(.floating)
        .accessibilityElement(children: .contain)
        .accessibilityLabel("\(card.brandName) \(card.cardName ?? ""), \(card.scope.displayName)")
    }
}

#Preview("지갑") {
    PreviewHost { WalletView(dependencies: $0.dependencies) }
}
