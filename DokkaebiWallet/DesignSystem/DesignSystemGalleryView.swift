import SwiftUI

/// 디자인 시스템 확인용 화면 (설정 > 앱 정보 > 디자인 시스템, DEBUG 빌드 전용).
/// 라이트·다크 모드와 글자 크기를 바꿔 가며 토큰과 컴포넌트를 확인한다.
struct DesignSystemGalleryView: View {
    @State private var text = ""
    @State private var segment = WalletFilter.all
    @State private var alert: DWAlertState?
    @State private var toast: DWToast?

    private let colorTokens: [(String, Color)] = [
        ("canvas", DWColor.canvas), ("surface", DWColor.surface), ("subtle", DWColor.subtle),
        ("primary", DWColor.primary), ("primarySoft", DWColor.primarySoft), ("gold", DWColor.gold),
        ("goldSoft", DWColor.goldSoft), ("beige", DWColor.beige), ("brown", DWColor.brown),
        ("textPrimary", DWColor.textPrimary), ("textSecondary", DWColor.textSecondary),
        ("income", DWColor.income), ("warning", DWColor.warning), ("danger", DWColor.danger), ("info", DWColor.info)
    ]

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: DWSpacing.cardGap) {
                DWCard(title: "브랜드") {
                    VStack(alignment: .leading, spacing: DWSpacing.md) {
                        DWLogo()
                        Text(AppDefaults.slogan).dwFont(.subheadline, color: DWColor.textSecondary)
                    }
                }
                DWCard(title: "색상") {
                    LazyVGrid(columns: [GridItem(.adaptive(minimum: 92), spacing: DWSpacing.sm)], spacing: DWSpacing.sm) {
                        ForEach(colorTokens, id: \.0) { name, color in
                            VStack(spacing: DWSpacing.xs) {
                                RoundedRectangle.dw(DWRadius.sm).fill(color).frame(height: 44)
                                    .overlay(RoundedRectangle.dw(DWRadius.sm).strokeBorder(DWColor.border, lineWidth: 0.5))
                                Text(name).dwFont(.caption, color: DWColor.textSecondary)
                            }
                        }
                    }
                }
                DWCard(title: "카테고리 팔레트") {
                    LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 8), spacing: DWSpacing.sm) {
                        ForEach(PaletteColor.allCases, id: \.self) { color in
                            Circle().fill(Color(palette: color)).frame(height: 28)
                        }
                    }
                }
                DWCard(title: "타이포그래피") {
                    VStack(alignment: .leading, spacing: DWSpacing.sm) {
                        ForEach(DWTypography.allCases, id: \.self) { style in
                            Text(style == .display || style == .amountLarge || style == .amountRow
                                 ? "\(style.sampleName) 1,250,000원" : "\(style.sampleName) 우리 가족의 지갑")
                                .dwFont(style)
                        }
                    }
                }
                DWCard(title: "버튼") {
                    VStack(spacing: DWSpacing.sm) {
                        DWButton(title: "Primary") {}
                        DWButton(title: "Secondary", kind: .secondary) {}
                        DWButton(title: "Tertiary", kind: .tertiary) {}
                        DWButton(title: "Destructive", kind: .destructive, size: .medium) {}
                    }
                }
                DWCard(title: "입력") {
                    VStack(spacing: DWSpacing.md) {
                        DWTextField(title: "이름", placeholder: "예: 우리집", text: $text)
                        DWTextField(title: "오류 예시", placeholder: "", text: .constant("잘못된 값"), errorMessage: "입력 내용을 확인해 주세요")
                        DWSegmentedControl(options: WalletFilter.allCases, selection: $segment) { $0.displayName }
                    }
                }
                DWCard(title: "지표") {
                    VStack(alignment: .leading, spacing: DWSpacing.md) {
                        DWProgressBar(progress: 0.5)
                        DWProgressBar(progress: 0.85, tint: DWColor.warning)
                        DWProgressBar(progress: 1.1, tint: DWColor.danger)
                        HStack { DWBadge(count: 3); DWTag(title: "공동"); DWChip(title: "선택됨", isSelected: true) {} }
                    }
                }
                DWCard(title: "상태") {
                    VStack(spacing: DWSpacing.md) {
                        DWLoadingView()
                        DWSkeletonCard(lines: 2)
                        DWErrorView(error: .network(.offline), retry: {})
                    }
                }
                DWCard(title: "알림창과 토스트") {
                    HStack {
                        DWButton(title: "알림창", kind: .secondary, size: .medium) {
                            alert = .destructive("삭제할까요?", message: "30일 동안 복구할 수 있어요.") {}
                        }
                        DWButton(title: "토스트", kind: .secondary, size: .medium) {
                            toast = DWToast(message: "저장했어요", systemImage: "checkmark.circle.fill")
                        }
                    }
                }
            }
            .dwScreenPadding()
            .padding(.bottom, DWSpacing.xxl)
        }
        .dwScreenBackground()
        .dwNavigationStyle("디자인 시스템", displayMode: .inline)
        .dwAlert($alert)
        .dwToast($toast)
    }
}

#Preview("디자인 시스템 - 라이트") {
    NavigationStack { DesignSystemGalleryView() }
}

#Preview("디자인 시스템 - 다크") {
    NavigationStack { DesignSystemGalleryView() }
        .preferredColorScheme(.dark)
}

#Preview("디자인 시스템 - 큰 글자") {
    NavigationStack { DesignSystemGalleryView() }
        .dynamicTypeSize(.accessibility2)
}
