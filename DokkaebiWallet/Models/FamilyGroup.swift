import Foundation

public enum MemberRole: String, Codable, Sendable, CaseIterable {
    case owner, admin, member

    public var displayName: String {
        switch self {
        case .owner: return "소유자"
        case .admin: return "관리자"
        case .member: return "구성원"
        }
    }

    public var canManageGroup: Bool { self != .member }
}

public struct FamilyGroup: Identifiable, Hashable, Codable, Sendable {
    public let id: UUID
    public var name: String
    public var monthStartDay: Int
    public var timeZoneIdentifier: String
    public var myRole: MemberRole
    public var memberCount: Int

    public init(id: UUID = UUID(), name: String, monthStartDay: Int = 1,
                timeZoneIdentifier: String = "Asia/Seoul", myRole: MemberRole, memberCount: Int) {
        self.id = id
        self.name = name
        self.monthStartDay = monthStartDay
        self.timeZoneIdentifier = timeZoneIdentifier
        self.myRole = myRole
        self.memberCount = memberCount
    }
}

/// 구성원 색상 토큰. 화면에서는 디자인 시스템 카테고리 팔레트로 변환한다.
public struct FamilyMember: Identifiable, Hashable, Codable, Sendable {
    public let id: UUID
    public var displayName: String
    public var nickname: String?
    public var role: MemberRole
    public var color: PaletteColor
    public var isMe: Bool

    public init(id: UUID = UUID(), displayName: String, nickname: String? = nil,
                role: MemberRole, color: PaletteColor, isMe: Bool = false) {
        self.id = id
        self.displayName = displayName
        self.nickname = nickname
        self.role = role
        self.color = color
        self.isMe = isMe
    }

    /// 그룹 안 별칭이 있으면 별칭, 없으면 표시 이름
    public var name: String { nickname ?? displayName }

    /// 아바타에 표시할 첫 글자
    public var initial: String { String(name.prefix(1)) }
}
