import SwiftUI
import UIKit

extension View {
    /// 화면 공통 배경 (아이보리 캔버스). List·Form의 기본 배경을 숨긴다.
    func dwScreenBackground() -> some View {
        scrollContentBackground(.hidden)
            .background(DWColor.canvas.ignoresSafeArea())
    }

    /// 내비게이션 바 공통 스타일: 기본은 큰 제목. 바 색은 `DWAppearance`가 설정한다
    /// (위쪽 끝에서는 캔버스색, 스크롤하면 반투명 소재).
    func dwNavigationStyle(_ title: String, displayMode: NavigationBarItem.TitleDisplayMode = .large) -> some View {
        navigationTitle(title)
            .navigationBarTitleDisplayMode(displayMode)
    }

    /// 화면 좌우 기본 여백
    func dwScreenPadding() -> some View {
        padding(.horizontal, DWSpacing.screenHorizontal)
    }
}

/// UIKit 바 외형 설정. 앱 시작 시 한 번 호출한다.
/// 색은 Asset Catalog의 동적 색상을 쓰므로 라이트·다크 모드에 맞춰 자동으로 바뀐다.
enum DWAppearance {
    @MainActor
    static func configure() {
        let canvas = UIColor(named: "bgCanvas") ?? .systemBackground
        let surface = UIColor(named: "bgSurface") ?? .secondarySystemBackground
        let primary = UIColor(named: "brandPrimary") ?? .systemGreen
        let textPrimary = UIColor(named: "textPrimary") ?? .label
        let tertiary = UIColor(named: "textTertiary") ?? .tertiaryLabel
        let border = UIColor(named: "borderDefault") ?? .separator

        // 하단 탭바: 흰 표면 + 얇은 위쪽 구분선, 선택 딥그린 / 비선택 3차 텍스트색
        let tab = UITabBarAppearance()
        tab.configureWithOpaqueBackground()
        tab.backgroundColor = surface
        tab.shadowColor = border
        for item in [tab.stackedLayoutAppearance, tab.inlineLayoutAppearance, tab.compactInlineLayoutAppearance] {
            item.normal.iconColor = tertiary
            item.normal.titleTextAttributes = [.foregroundColor: tertiary]
            item.selected.iconColor = primary
            item.selected.titleTextAttributes = [.foregroundColor: primary]
        }
        UITabBar.appearance().standardAppearance = tab
        UITabBar.appearance().scrollEdgeAppearance = tab

        // 내비게이션 바: 위쪽 끝에서는 캔버스와 같은 색(투명해 보이게), 제목은 기본 텍스트색
        let nav = UINavigationBarAppearance()
        nav.configureWithTransparentBackground()
        nav.backgroundColor = canvas
        nav.titleTextAttributes = [.foregroundColor: textPrimary]
        nav.largeTitleTextAttributes = [.foregroundColor: textPrimary]
        UINavigationBar.appearance().scrollEdgeAppearance = nav
        UINavigationBar.appearance().compactScrollEdgeAppearance = nav

        let scrolled = UINavigationBarAppearance()
        scrolled.configureWithDefaultBackground()
        scrolled.titleTextAttributes = [.foregroundColor: textPrimary]
        scrolled.largeTitleTextAttributes = [.foregroundColor: textPrimary]
        UINavigationBar.appearance().standardAppearance = scrolled
        UINavigationBar.appearance().compactAppearance = scrolled
        UINavigationBar.appearance().tintColor = primary
    }
}

/// 알약 모양 세그먼트 컨트롤 (DESIGN_SYSTEM.md §5). iOS 기본보다 부드러운 톤.
struct DWSegmentedControl<Option: Hashable>: View {
    let options: [Option]
    @Binding var selection: Option
    let title: (Option) -> String

    @Namespace private var namespace

    var body: some View {
        HStack(spacing: 2) {
            ForEach(options, id: \.self) { option in
                let isSelected = option == selection
                Button {
                    withAnimation(DWMotion.quick) { selection = option }
                } label: {
                    Text(title(option))
                        .dwFont(.subheadline, color: isSelected ? DWColor.textPrimary : DWColor.textSecondary)
                        .fontWeight(isSelected ? .semibold : .regular)
                        .frame(maxWidth: .infinity, minHeight: 34)
                        .background {
                            if isSelected {
                                Capsule()
                                    .fill(DWColor.surface)
                                    .dwShadow(.card)
                                    .matchedGeometryEffect(id: "selection", in: namespace)
                            }
                        }
                        .contentShape(Capsule())
                }
                .buttonStyle(.plain)
                .accessibilityAddTraits(isSelected ? .isSelected : [])
            }
        }
        .padding(3)
        .background(DWColor.subtle, in: Capsule())
        .sensoryFeedback(.selection, trigger: selection)
    }
}

#Preview("세그먼트") {
    struct Demo: View {
        @State private var mode = CalendarDisplayMode.month
        var body: some View {
            DWSegmentedControl(options: CalendarDisplayMode.allCases, selection: $mode) { $0.displayName }
                .padding()
                .background(DWColor.canvas)
        }
    }
    return Demo()
}
