import Foundation
import Observation

public enum TodoListFilter: String, CaseIterable, Sendable {
    case mine, family, done

    public var displayName: String {
        switch self {
        case .mine: return "내 할 일"
        case .family: return "가족"
        case .done: return "완료"
        }
    }
}

@MainActor
@Observable
public final class TodoViewModel {
    public private(set) var state: ViewState<[TodoItem]> = .idle
    public var filter: TodoListFilter = .mine { didSet { rebuild() } }
    public private(set) var lastError: AppError?

    private var items: [TodoItem] = []
    private var meID: UUID?
    private let repository: any TodoRepository
    private let mock: Bool

    public init(dependencies: AppDependencies) {
        repository = dependencies.todos
        mock = dependencies.isUsingMockData
    }

    public var isUsingMockData: Bool { mock }

    public func load(groupID: UUID, meID: UUID?) async {
        self.meID = meID
        if items.isEmpty { state = .loading }
        do {
            items = try await repository.fetchTodos(groupID: groupID)
            rebuild()
        } catch {
            state = .failed(.wrap(error))
        }
    }

    /// 완료 체크 토글 (FR-TASK-02). 낙관적으로 반영하고 실패하면 되돌린다.
    public func toggleDone(_ item: TodoItem) async {
        guard let index = items.firstIndex(where: { $0.id == item.id }) else { return }
        let previous = items[index].status
        let next: TodoStatus = previous == .done ? .todo : .done
        items[index].status = next
        rebuild()
        do {
            items[index] = try await repository.updateStatus(todoID: item.id, status: next)
            lastError = nil
        } catch {
            items[index].status = previous
            lastError = .wrap(error)
        }
        rebuild()
    }

    private func rebuild() {
        let visible: [TodoItem]
        switch filter {
        case .mine:
            visible = meID.map { id in items.pendingSorted(for: id).filter { $0.assigneeIDs.contains(id) } } ?? []
        case .family:
            visible = meID.map { items.pendingSorted(for: $0) } ?? items.filter { !$0.isDone }
        case .done:
            visible = items.filter(\.isDone)
        }
        state = visible.isEmpty ? .empty : .loaded(visible)
    }
}
