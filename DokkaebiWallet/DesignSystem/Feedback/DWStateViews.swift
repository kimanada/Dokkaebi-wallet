import SwiftUI

/// 빈 상태 (DESIGN_SYSTEM.md §5, USER_FLOW.md §3)
struct DWEmptyState: View {
    var systemImage: String = "sparkles"
    let title: String
    var message: String?
    var actionTitle: String?
    var action: (() -> Void)?

    var body: some View {
        VStack(spacing: DWSpacing.md) {
            ZStack {
                LuckyDotPattern(dotSize: 6, spacing: 10)
                    .foregroundStyle(DWColor.beige)
                    .frame(width: 64, height: 64)
                Image(systemName: systemImage)
                    .font(.system(size: 26, weight: .medium))
                    .foregroundStyle(DWColor.brown)
                    .padding(DWSpacing.md)
                    .background(DWColor.surface, in: Circle())
            }
            .accessibilityHidden(true)
            Text(title)
                .dwFont(.headline)
                .multilineTextAlignment(.center)
            if let message {
                Text(message)
                    .dwFont(.subheadline, color: DWColor.textSecondary)
                    .multilineTextAlignment(.center)
            }
            if let actionTitle, let action {
                DWButton(title: actionTitle, kind: .secondary, size: .medium, fillsWidth: false, action: action)
                    .padding(.top, DWSpacing.xs)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, DWSpacing.xxxl)
        .padding(.horizontal, DWSpacing.xl)
        .accessibilityElement(children: .contain)
    }
}

/// 로딩 표시
struct DWLoadingView: View {
    var message: String = "불러오는 중이에요"

    var body: some View {
        VStack(spacing: DWSpacing.md) {
            ProgressView()
                .controlSize(.large)
                .tint(DWColor.primary)
            Text(message).dwFont(.subheadline, color: DWColor.textSecondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, DWSpacing.xxxl)
        .accessibilityElement(children: .combine)
    }
}

/// 스켈레톤 자리 표시자. 동작 줄이기가 켜져 있으면 깜빡임을 멈춘다.
struct DWSkeleton: View {
    var height: CGFloat = 16
    var width: CGFloat?

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var isDimmed = false

    var body: some View {
        RoundedRectangle.dw(DWRadius.sm)
            .fill(DWColor.subtle)
            .frame(width: width, height: height)
            .opacity(isDimmed ? 0.5 : 1)
            .onAppear {
                guard !reduceMotion else { return }
                withAnimation(.easeInOut(duration: 0.9).repeatForever(autoreverses: true)) { isDimmed = true }
            }
            .accessibilityHidden(true)
    }
}

/// 카드 모양 스켈레톤 묶음 (첫 로딩용)
struct DWSkeletonCard: View {
    var lines = 3

    var body: some View {
        VStack(alignment: .leading, spacing: DWSpacing.md) {
            DWSkeleton(height: 20, width: 120)
            ForEach(0..<lines, id: \.self) { _ in DWSkeleton(height: 14) }
        }
        .padding(DWSpacing.cardPadding)
        .dwCardBackground()
        .accessibilityElement()
        .accessibilityLabel("불러오는 중")
    }
}

/// 오류 표시. 재시도할 수 있는 오류면 [다시 시도] 버튼을 보여준다.
struct DWErrorView: View {
    let error: AppError
    var retry: (() -> Void)?

    var body: some View {
        VStack(spacing: DWSpacing.md) {
            Image(systemName: icon)
                .font(.system(size: 30, weight: .medium))
                .foregroundStyle(DWColor.danger)
                .accessibilityHidden(true)
            Text(error.title).dwFont(.headline).multilineTextAlignment(.center)
            Text(error.message)
                .dwFont(.subheadline, color: DWColor.textSecondary)
                .multilineTextAlignment(.center)
            if error.isRetryable, let retry {
                DWButton(title: "다시 시도", systemImage: "arrow.clockwise", kind: .secondary, size: .medium,
                         fillsWidth: false, action: retry)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, DWSpacing.xxxl)
        .padding(.horizontal, DWSpacing.xl)
        .accessibilityElement(children: .contain)
    }

    private var icon: String {
        switch error {
        case .network: return "wifi.slash"
        case .forbidden, .unauthorized: return "lock"
        default: return "exclamationmark.triangle"
        }
    }
}

/// `ViewState`에 따라 로딩·빈 상태·오류·내용을 그린다.
struct DWStateView<Value, Content: View, Empty: View>: View {
    let state: ViewState<Value>
    var retry: (() -> Void)?
    @ViewBuilder let empty: () -> Empty
    @ViewBuilder let content: (Value) -> Content

    var body: some View {
        switch state {
        case .idle, .loading:
            DWLoadingView()
        case .empty:
            empty()
        case .failed(let error):
            DWErrorView(error: error, retry: retry)
        case .loaded(let value):
            content(value)
        }
    }
}

#Preview("상태 화면") {
    ScrollView {
        VStack(spacing: DWSpacing.cardGap) {
            DWEmptyState(systemImage: "list.bullet.rectangle", title: "아직 이번 달 기록이 없어요",
                         message: "첫 거래를 기록하면 소비 흐름을 보여드릴게요",
                         actionTitle: "첫 거래 기록하기", action: {})
                .dwCardBackground()
            DWLoadingView().dwCardBackground()
            DWSkeletonCard()
            DWErrorView(error: .network(.offline), retry: {}).dwCardBackground()
            DWErrorView(error: .forbidden).dwCardBackground()
        }
        .padding(DWSpacing.screenHorizontal)
    }
    .background(DWColor.canvas)
}
