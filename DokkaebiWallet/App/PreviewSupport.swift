import SwiftUI

/// Preview용 호스트: Mock 컨테이너를 만들고 그룹 정보를 불러온 뒤 내용을 그린다.
/// 사용 예: `#Preview { PreviewHost { HomeView(dependencies: $0.dependencies) } }`
struct PreviewHost<Content: View>: View {
    var behavior: MockBehavior = .instant
    var embedsInNavigationStack = true
    @ViewBuilder let content: (AppContainer) -> Content

    @State private var container: AppContainer?

    var body: some View {
        Group {
            if let container, container.session.currentGroup != nil {
                Group {
                    if embedsInNavigationStack {
                        NavigationStack {
                            content(container)
                                .navigationDestination(for: AppRoute.self) { AppRouteDestination(route: $0) }
                        }
                    } else {
                        content(container)
                    }
                }
                .environment(container)
                .environment(container.session)
                .environment(container.router)
            } else {
                ProgressView()
            }
        }
        .task {
            let container = AppContainer.preview(behavior: behavior)
            await container.session.load()
            self.container = container
        }
    }
}
