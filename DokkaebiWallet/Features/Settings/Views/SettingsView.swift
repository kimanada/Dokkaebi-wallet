import SwiftUI

/// 설정 (USER_FLOW.md S-SET). 항목은 자리만 마련하고 이후 단계에서 연결한다.
struct SettingsView: View {
    @Environment(AppContainer.self) private var container
    @Environment(AppRouter.self) private var router
    @State private var alert: DWAlertState?

    var body: some View {
        List {
            Section("프로필") {
                row("프로필 편집", "person.crop.circle")
            }
            Section("알림") {
                row("알림 설정", "bell.badge")
                row("방해 금지 시간", "moon")
            }
            Section("보안") {
                row("앱 잠금 (Face ID)", "faceid")
                row("지갑 잠금", "lock.rectangle")
            }
            Section("데이터") {
                row("데이터 내보내기", "square.and.arrow.up")
            }
            Section("계정") {
                Button("로그아웃") {
                    alert = .notice("로그아웃은 로그인 기능과 함께 연결돼요")
                }
                .foregroundStyle(DWColor.textPrimary)
                Button("계정 삭제", role: .destructive) {
                    alert = .destructive("계정을 삭제할까요?", message: "계정 삭제는 로그인 기능과 함께 연결돼요.",
                                         confirmTitle: "확인") {}
                }
            }
            Section("앱 정보") {
                LabeledContent("버전", value: Bundle.main.appVersionText)
                LabeledContent("환경", value: container.dependencies.configuration.environmentName)
                LabeledContent("데이터", value: container.dependencies.isUsingMockData ? "샘플 데이터" : "실서비스")
                #if DEBUG
                NavigationLink("디자인 시스템", value: AppRoute.designSystemGallery)
                #endif
            }
        }
        .listStyle(.insetGrouped)
        .tint(DWColor.primary)
        .dwScreenBackground()
        .dwNavigationStyle("설정", displayMode: .inline)
        .dwAlert($alert)
    }

    private func row(_ title: String, _ systemImage: String) -> some View {
        Button {
            router.present(.comingSoon(feature: title))
        } label: {
            Label(title, systemImage: systemImage)
                .foregroundStyle(DWColor.textPrimary)
        }
    }
}

extension Bundle {
    /// 예: "1.0 (1)"
    var appVersionText: String {
        let version = infoDictionary?["CFBundleShortVersionString"] as? String ?? "-"
        let build = infoDictionary?["CFBundleVersion"] as? String ?? "-"
        return "\(version) (\(build))"
    }
}

#Preview("설정") {
    PreviewHost { _ in SettingsView() }
}
