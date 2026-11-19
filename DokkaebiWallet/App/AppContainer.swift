import Foundation
import Observation

/// 앱 전역 객체 묶음. SwiftUI 환경(`.environment`)으로 주입한다 (APP_STRUCTURE.md §3).
@MainActor
@Observable
public final class AppContainer {
    public let dependencies: AppDependencies
    public let session: SessionViewModel
    public let router: AppRouter

    public init(dependencies: AppDependencies) {
        self.dependencies = dependencies
        self.session = SessionViewModel(repository: dependencies.family)
        self.router = AppRouter()
    }

    /// 실행 환경에 맞는 컨테이너. 현재는 데이터 연결 전이므로 항상 Mock 데이터를 쓴다.
    public static func live() -> AppContainer {
        let configuration = AppConfiguration.current
        let arguments = ProcessInfo.processInfo.arguments
        // UI 테스트는 지연 없이, 앱 실행은 실제와 비슷한 짧은 지연을 둔다.
        let behavior: MockBehavior = arguments.contains("-UITestMock") ? .instant : .realistic
        return AppContainer(dependencies: .mock(behavior: behavior, configuration: configuration))
    }

    /// SwiftUI Preview·테스트용 (그룹 정보는 `session.load()`를 호출해야 채워진다)
    public static func preview(behavior: MockBehavior = .instant) -> AppContainer {
        AppContainer(dependencies: .mock(behavior: behavior))
    }
}
