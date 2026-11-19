import SwiftUI

/// 공지사항 목록 (FR-NOT)
struct NoticeListView: View {
    @Environment(SessionViewModel.self) private var session
    @Environment(AppRouter.self) private var router
    @State private var viewModel: NoticeViewModel

    init(dependencies: AppDependencies) {
        _viewModel = State(initialValue: NoticeViewModel(dependencies: dependencies))
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: DWSpacing.md) {
                if viewModel.isUsingMockData { MockDataBanner() }
                DWStateView(state: viewModel.state, retry: { Task { await reload() } }) {
                    DWEmptyState(systemImage: "megaphone", title: "가족에게 전할 소식을 남겨 보세요",
                                 actionTitle: "공지 쓰기") { router.present(.comingSoon(feature: "공지 작성")) }
                        .dwCardBackground()
                } content: { notices in
                    ForEach(notices) { notice in
                        NavigationLink(value: AppRoute.noticeDetail(notice)) {
                            NoticeRowView(notice: notice)
                                .padding(DWSpacing.lg)
                                .dwCardBackground()
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
            .dwScreenPadding()
            .padding(.bottom, DWSpacing.xxl)
        }
        .dwScreenBackground()
        .dwNavigationStyle("공지사항", displayMode: .inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button { router.present(.comingSoon(feature: "공지 작성")) } label: { Image(systemName: "square.and.pencil") }
                    .accessibilityLabel("공지 쓰기")
            }
        }
        .task(id: session.groupRevision) { await reload() }
    }

    private func reload() async {
        guard let group = session.currentGroup else { return }
        await viewModel.load(groupID: group.id)
    }
}

/// 공지 한 줄. 고정 공지는 골드 배경, 읽지 않은 공지는 굵은 제목과 점.
struct NoticeRowView: View {
    let notice: Notice
    var compact = false
    @Environment(SessionViewModel.self) private var session
    private let formatting = DateFormatting()

    var body: some View {
        HStack(alignment: .top, spacing: DWSpacing.md) {
            Circle()
                .fill(notice.isReadByMe ? Color.clear : DWColor.primary)
                .frame(width: 8, height: 8)
                .padding(.top, 7)
                .accessibilityHidden(true)
            VStack(alignment: .leading, spacing: DWSpacing.xs) {
                HStack(spacing: DWSpacing.xs) {
                    if notice.isPinned {
                        Image(systemName: "pin.fill").font(.caption).foregroundStyle(DWColor.gold)
                    }
                    Text(notice.title)
                        .dwFont(.headline)
                        .fontWeight(notice.isReadByMe ? .medium : .bold)
                        .lineLimit(1)
                }
                if !compact {
                    Text(notice.body).dwFont(.subheadline, color: DWColor.textSecondary).lineLimit(2)
                }
                Text(meta).dwFont(.caption, color: DWColor.textTertiary)
            }
            Spacer(minLength: 0)
        }
        .padding(compact && notice.isPinned ? DWSpacing.sm : 0)
        .background(compact && notice.isPinned ? DWColor.goldSoft : .clear, in: RoundedRectangle.dw(DWRadius.md))
        .contentShape(Rectangle())
        .accessibilityElement(children: .combine)
        .accessibilityLabel([notice.isPinned ? "고정 공지" : nil, notice.isReadByMe ? nil : "읽지 않음",
                             notice.title, meta].compactMap { $0 }.joined(separator: ", "))
    }

    private var meta: String {
        let author = session.member(id: notice.authorID)?.name ?? "구성원"
        return "\(author) · \(formatting.shortDate(notice.createdAt)) · \(notice.readCount)/\(notice.memberCount)명 읽음"
    }
}

/// 공지 상세 (읽음 기록은 이후 단계에서 서버와 연결)
struct NoticeDetailView: View {
    let notice: Notice
    @Environment(SessionViewModel.self) private var session
    private let formatting = DateFormatting()

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: DWSpacing.cardGap) {
                DWCard {
                    VStack(alignment: .leading, spacing: DWSpacing.md) {
                        if notice.isPinned {
                            DWTag(title: "고정 공지", systemImage: "pin.fill", foreground: DWColor.brown, background: DWColor.goldSoft)
                        }
                        Text(notice.title).dwFont(.title2)
                        if let author = session.member(id: notice.authorID) {
                            HStack(spacing: DWSpacing.sm) {
                                DWAvatar(member: author, size: 24)
                                Text("\(author.name) · \(formatting.dayLabel(notice.createdAt)) \(formatting.time(notice.createdAt))")
                                    .dwFont(.footnote, color: DWColor.textSecondary)
                            }
                        }
                        Divider().overlay(DWColor.border)
                        Text(notice.body).dwFont(.body)
                    }
                }
                DWCard(title: "읽음 현황", subtitle: "\(notice.readCount)/\(notice.memberCount)명 읽음") {
                    DWProgressBar(progress: Double(notice.readCount) / Double(max(notice.memberCount, 1)))
                }
            }
            .dwScreenPadding()
            .padding(.vertical, DWSpacing.lg)
        }
        .dwScreenBackground()
        .dwNavigationStyle("공지", displayMode: .inline)
    }
}

#Preview("공지 목록") {
    PreviewHost { NoticeListView(dependencies: $0.dependencies) }
}
