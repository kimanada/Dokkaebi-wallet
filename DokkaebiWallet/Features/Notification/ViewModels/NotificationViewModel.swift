import Foundation
import Observation

@MainActor
@Observable
public final class NotificationViewModel {
    public private(set) var state: ViewState<[AppNotification]> = .idle
    private var items: [AppNotification] = []
    private let repository: any NotificationRepository
    private let mock: Bool

    public init(dependencies: AppDependencies) {
        repository = dependencies.notifications
        mock = dependencies.isUsingMockData
    }

    public var isUsingMockData: Bool { mock }
    public var unreadCount: Int { items.filter { !$0.isRead }.count }

    public func load() async {
        if items.isEmpty { state = .loading }
        do {
            items = try await repository.fetchNotifications()
            publish()
        } catch {
            state = .failed(.wrap(error))
        }
    }

    public func markAsRead(_ item: AppNotification) async {
        guard !item.isRead else { return }
        await update(ids: [item.id])
    }

    public func markAllAsRead() async {
        await update(ids: items.filter { !$0.isRead }.map(\.id))
    }

    public func delete(_ item: AppNotification) async {
        let backup = items
        items.removeAll { $0.id == item.id }
        publish()
        do {
            try await repository.delete(id: item.id)
        } catch {
            items = backup
            publish()
        }
    }

    private func update(ids: [UUID]) async {
        guard !ids.isEmpty else { return }
        let backup = items
        for index in items.indices where ids.contains(items[index].id) { items[index].isRead = true }
        publish()
        do {
            try await repository.markAsRead(ids: ids)
        } catch {
            items = backup
            publish()
        }
    }

    private func publish() {
        state = items.isEmpty ? .empty : .loaded(items)
    }
}
