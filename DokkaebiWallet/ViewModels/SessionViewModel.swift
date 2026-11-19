import Foundation
import Observation

/// 여러 화면이 함께 쓰는 세션 상태: 참여 중인 가족 그룹, 현재 그룹, 구성원 (FR-GRP-02).
@MainActor
@Observable
public final class SessionViewModel {
    public private(set) var groups: [FamilyGroup] = []
    public private(set) var currentGroup: FamilyGroup?
    public private(set) var members: [FamilyMember] = []
    public private(set) var loadError: AppError?
    /// 그룹이 바뀔 때마다 증가한다. 각 화면은 이 값을 보고 다시 불러온다.
    public private(set) var groupRevision = 0

    private let repository: any FamilyRepository

    public init(repository: any FamilyRepository) {
        self.repository = repository
    }

    public var me: FamilyMember? { members.first(where: \.isMe) }

    public func member(id: UUID) -> FamilyMember? {
        members.first { $0.id == id }
    }

    public func load() async {
        do {
            let groups = try await repository.fetchGroups()
            self.groups = groups
            let target = currentGroup.flatMap { current in groups.first { $0.id == current.id } } ?? groups.first
            if let target { try await activate(target) }
            loadError = nil
        } catch let error as AppError {
            loadError = error
        } catch {
            loadError = .unknown(description: String(describing: error))
        }
    }

    public func select(_ group: FamilyGroup) async {
        guard group.id != currentGroup?.id else { return }
        do {
            try await activate(group)
        } catch let error as AppError {
            loadError = error
        } catch {
            loadError = .unknown(description: String(describing: error))
        }
    }

    private func activate(_ group: FamilyGroup) async throws {
        let members = try await repository.fetchMembers(groupID: group.id)
        currentGroup = group
        self.members = members
        groupRevision += 1
    }
}
