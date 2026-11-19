import SwiftUI

/// 전체 메뉴 탭: 공지사항, 할 일, 알림 센터, 가족 관리, 설정 (APP_STRUCTURE.md §5.1)
struct MoreMenuView: View {
    private struct MenuItem: Identifiable {
        let route: AppRoute
        let title: String
        let subtitle: String
        let systemImage: String
        let color: PaletteColor
        var id: String { title }
    }

    private let items: [MenuItem] = [
        MenuItem(route: .notices, title: "공지사항", subtitle: "가족에게 전하는 소식", systemImage: "megaphone", color: .gold),
        MenuItem(route: .todos, title: "할 일", subtitle: "담당자와 마감일 관리", systemImage: "checklist", color: .pine),
        MenuItem(route: .notifications, title: "알림 센터", subtitle: "지출·공지·일정 알림", systemImage: "bell", color: .maple),
        MenuItem(route: .family, title: "가족 관리", subtitle: "구성원, 초대, 그룹 설정", systemImage: "person.2", color: .indigo),
        MenuItem(route: .settings, title: "설정", subtitle: "알림, 보안, 계정", systemImage: "gearshape", color: .ink)
    ]

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: DWSpacing.cardGap) {
                ProfileHeader()
                VStack(spacing: 0) {
                    ForEach(items) { item in
                        NavigationLink(value: item.route) {
                            HStack(spacing: DWSpacing.md) {
                                CategoryIconView(systemImage: item.systemImage, color: item.color, size: 40)
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(item.title).dwFont(.headline)
                                    Text(item.subtitle).dwFont(.footnote, color: DWColor.textSecondary)
                                }
                                Spacer()
                                Image(systemName: "chevron.right")
                                    .font(.footnote.weight(.semibold))
                                    .foregroundStyle(DWColor.textTertiary)
                            }
                            .padding(.vertical, DWSpacing.md)
                            .contentShape(Rectangle())
                        }
                        .buttonStyle(.plain)
                        .accessibilityIdentifier("more.\(item.title)")
                        if item.id != items.last?.id {
                            Divider().overlay(DWColor.border).padding(.leading, 52)
                        }
                    }
                }
                .padding(.horizontal, DWSpacing.lg)
                .dwCardBackground()

                Text("\(AppDefaults.serviceName) · \(AppDefaults.slogan)")
                    .dwFont(.footnote, color: DWColor.textTertiary)
                    .frame(maxWidth: .infinity)
                    .padding(.top, DWSpacing.md)
            }
            .dwScreenPadding()
            .padding(.bottom, DWSpacing.xxl)
        }
        .dwScreenBackground()
        .dwNavigationStyle("전체")
        .accessibilityIdentifier("screen.more")
    }
}

private struct ProfileHeader: View {
    @Environment(SessionViewModel.self) private var session

    var body: some View {
        HStack(spacing: DWSpacing.md) {
            if let me = session.me {
                DWAvatar(member: me, size: 52)
            }
            VStack(alignment: .leading, spacing: 2) {
                Text(session.me?.displayName ?? "-").dwFont(.title3)
                Text("\(session.currentGroup?.name ?? "") · \(session.currentGroup?.myRole.displayName ?? "")")
                    .dwFont(.footnote, color: DWColor.textSecondary)
            }
            Spacer()
        }
        .padding(DWSpacing.cardPadding)
        .dwCardBackground()
        .accessibilityElement(children: .combine)
    }
}

#Preview("전체 메뉴") {
    PreviewHost { _ in MoreMenuView() }
}
