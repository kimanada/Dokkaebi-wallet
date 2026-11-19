import SwiftUI

/// 가족 관리: 구성원 목록과 역할, 초대 (FR-GRP)
struct FamilyView: View {
    @Environment(SessionViewModel.self) private var session
    @Environment(AppRouter.self) private var router

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: DWSpacing.cardGap) {
                MockDataBanner()
                if let group = session.currentGroup {
                    DWCard(title: group.name, subtitle: "구성원 \(session.members.count)명 · 내 역할 \(group.myRole.displayName)") {
                        VStack(spacing: 0) {
                            ForEach(session.members) { member in
                                HStack(spacing: DWSpacing.md) {
                                    DWAvatar(member: member, size: 40)
                                    VStack(alignment: .leading, spacing: 2) {
                                        HStack(spacing: DWSpacing.xs) {
                                            Text(member.name).dwFont(.headline)
                                            if member.isMe { DWTag(title: "나", foreground: DWColor.primary, background: DWColor.primarySoft) }
                                        }
                                        Text(member.displayName).dwFont(.footnote, color: DWColor.textSecondary)
                                    }
                                    Spacer()
                                    RoleBadge(role: member.role)
                                }
                                .padding(.vertical, DWSpacing.sm)
                                .accessibilityElement(children: .combine)
                                if member.id != session.members.last?.id {
                                    Divider().overlay(DWColor.border).padding(.leading, 52)
                                }
                            }
                        }
                    }

                    if group.myRole.canManageGroup {
                        DWButton(title: "가족 초대하기", systemImage: "person.badge.plus") {
                            router.present(.comingSoon(feature: "가족 초대"))
                        }
                    }

                    DWCard(title: "그룹 설정") {
                        VStack(spacing: 0) {
                            DetailRow(title: "월 시작일", value: "매월 \(group.monthStartDay)일")
                            DetailRow(title: "시간대", value: group.timeZoneIdentifier)
                            DetailRow(title: "통화", value: AppDefaults.currencyCode, isLast: true)
                        }
                    }
                }
            }
            .dwScreenPadding()
            .padding(.bottom, DWSpacing.xxl)
        }
        .dwScreenBackground()
        .dwNavigationStyle("가족 관리", displayMode: .inline)
    }
}

struct RoleBadge: View {
    let role: MemberRole

    var body: some View {
        switch role {
        case .owner: DWTag(title: role.displayName, systemImage: "crown.fill", foreground: DWColor.brown, background: DWColor.goldSoft)
        case .admin: DWTag(title: role.displayName, foreground: DWColor.primary, background: DWColor.primarySoft)
        case .member: DWTag(title: role.displayName)
        }
    }
}

/// 가족 그룹 전환 시트 (USER_FLOW.md F16)
struct GroupSwitcherSheet: View {
    @Environment(SessionViewModel.self) private var session
    @Environment(AppRouter.self) private var router
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            List {
                Section("참여 중인 가족") {
                    ForEach(session.groups) { group in
                        Button {
                            Task {
                                await session.select(group)
                                dismiss()
                            }
                        } label: {
                            HStack(spacing: DWSpacing.md) {
                                Image(systemName: "house.fill")
                                    .foregroundStyle(DWColor.primary)
                                    .frame(width: 36, height: 36)
                                    .background(DWColor.primarySoft, in: Circle())
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(group.name).dwFont(.headline)
                                    Text("구성원 \(group.memberCount)명 · \(group.myRole.displayName)")
                                        .dwFont(.footnote, color: DWColor.textSecondary)
                                }
                                Spacer()
                                if group.id == session.currentGroup?.id {
                                    Image(systemName: "checkmark.circle.fill").foregroundStyle(DWColor.primary)
                                        .accessibilityLabel("현재 선택됨")
                                }
                            }
                        }
                        .buttonStyle(.plain)
                        .listRowBackground(DWColor.surface)
                    }
                }
                Section {
                    Button("새 가족 만들기", systemImage: "plus") { showComingSoon("가족 그룹 만들기") }
                    Button("초대 코드로 참여", systemImage: "ticket") { showComingSoon("초대 코드로 참여") }
                }
                .listRowBackground(DWColor.surface)
                .foregroundStyle(DWColor.primary)
            }
            .listStyle(.insetGrouped)
            .dwScreenBackground()
            .dwNavigationStyle("가족 선택", displayMode: .inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("닫기") { dismiss() }
                }
            }
        }
    }

    private func showComingSoon(_ feature: String) {
        dismiss()
        router.present(.comingSoon(feature: feature))
    }
}

/// 아직 구현되지 않은 기능 안내 시트
struct ComingSoonSheet: View {
    let feature: String
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        VStack(spacing: DWSpacing.lg) {
            DWEmptyState(systemImage: "hammer", title: "\(feature) 기능을 준비하고 있어요",
                         message: "현재는 화면 구조와 디자인을 먼저 만든 단계예요.\n다음 개발 단계에서 실제 데이터와 함께 연결할게요.")
            DWButton(title: "확인") { dismiss() }
        }
        .padding(DWSpacing.xl)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(DWColor.surface.ignoresSafeArea())
        .accessibilityIdentifier("comingSoon")
    }
}

#Preview("가족 관리") {
    PreviewHost { _ in FamilyView() }
}

#Preview("그룹 전환") {
    PreviewHost(embedsInNavigationStack: false) { _ in GroupSwitcherSheet() }
}

#Preview("준비 중") {
    ComingSoonSheet(feature: "거래 등록")
}
