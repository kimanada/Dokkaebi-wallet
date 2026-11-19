import Foundation

/// Mock Repository의 동작 설정. 로딩·오류 상태를 Preview와 테스트에서 재현할 때 쓴다.
public struct MockBehavior: Sendable {
    public var delay: Duration
    public var failure: AppError?

    public init(delay: Duration = .zero, failure: AppError? = nil) {
        self.delay = delay
        self.failure = failure
    }

    public static let instant = MockBehavior()
    public static let realistic = MockBehavior(delay: .milliseconds(450))
    public static let offline = MockBehavior(failure: .network(.offline))

    func perform() async throws {
        if delay > .zero { try await Task.sleep(for: delay) }
        if let failure { throw failure }
    }
}
