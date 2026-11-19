import Foundation
import Observation

@MainActor
@Observable
public final class NoticeViewModel {
    public private(set) var state: ViewState<[Notice]> = .idle
    private let repository: any NoticeRepository
    private let mock: Bool

    public init(dependencies: AppDependencies) {
        repository = dependencies.notices
        mock = dependencies.isUsingMockData
    }

    public var isUsingMockData: Bool { mock }

    public func load(groupID: UUID) async {
        if state.value == nil { state = .loading }
        do {
            let notices = try await repository.fetchNotices(groupID: groupID)
            state = notices.isEmpty ? .empty : .loaded(notices)
        } catch {
            state = .failed(.wrap(error))
        }
    }
}
