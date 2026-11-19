import SwiftUI

/// 루트 화면. 인증과 온보딩은 이후 단계에서 붙이고, 현재는 그룹 정보를 불러온 뒤 탭 화면을 보여준다.
struct RootView: View {
    @Environment(SessionViewModel.self) private var session

    var body: some View {
        Group {
            if session.currentGroup != nil {
                MainTabView()
            } else if let error = session.loadError {
                DWErrorView(error: error) {
                    Task { await session.load() }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(DWColor.canvas.ignoresSafeArea())
            } else {
                SplashView()
            }
        }
        .task {
            if session.currentGroup == nil { await session.load() }
        }
    }
}

/// 첫 로딩 화면
struct SplashView: View {
    var body: some View {
        VStack(spacing: DWSpacing.lg) {
            DWBrandMark(size: 88)
            VStack(spacing: DWSpacing.xs) {
                Text(AppDefaults.serviceName).dwFont(.title1)
                Text(AppDefaults.serviceNameEnglish)
                    .font(.system(.footnote, weight: .semibold))
                    .kerning(2)
                    .foregroundStyle(DWColor.brown)
            }
            Text(AppDefaults.slogan).dwFont(.subheadline, color: DWColor.textSecondary)
            ProgressView().tint(DWColor.primary).padding(.top, DWSpacing.lg)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(DWColor.canvas.ignoresSafeArea())
        .accessibilityElement(children: .combine)
        .accessibilityIdentifier("splash")
    }
}

#Preview("루트") {
    let container = AppContainer.preview(behavior: .realistic)
    return RootView()
        .environment(container)
        .environment(container.session)
        .environment(container.router)
}

#Preview("스플래시") {
    SplashView()
}
