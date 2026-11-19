import SwiftUI

/// 알림 센터 (FR-NTF)
struct NotificationListView: View {
    @State private var viewModel: NotificationViewModel
    private let formatting = DateFormatting()

    init(dependencies: AppDependencies) {
        _viewModel = State(initialValue: NotificationViewModel(dependencies: dependencies))
    }

    var body: some View {
        List {
            if viewModel.isUsingMockData {
                MockDataBanner()
                    .listRowBackground(Color.clear)
                    .listRowInsets(EdgeInsets(top: 0, leading: 0, bottom: DWSpacing.sm, trailing: 0))
                    .listRowSeparator(.hidden)
            }
            DWStateView(state: viewModel.state, retry: { Task { await viewModel.load() } }) {
                DWEmptyState(systemImage: "bell", title: "새로운 소식이 없어요")
                    .listRowBackground(Color.clear)
            } content: { items in
                ForEach(items) { item in
                    NotificationRow(item: item, formatting: formatting)
                        .listRowBackground(DWColor.surface)
                        .contentShape(Rectangle())
                        .onTapGesture { Task { await viewModel.markAsRead(item) } }
                        .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                            Button(role: .destructive) {
                                Task { await viewModel.delete(item) }
                            } label: {
                                Label("삭제", systemImage: "trash")
                            }
                        }
                        .swipeActions(edge: .leading) {
                            if !item.isRead {
                                Button {
                                    Task { await viewModel.markAsRead(item) }
                                } label: {
                                    Label("읽음", systemImage: "envelope.open")
                                }
                                .tint(DWColor.primary)
                            }
                        }
                }
            }
        }
        .listStyle(.insetGrouped)
        .dwScreenBackground()
        .dwNavigationStyle("알림 센터", displayMode: .inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button("모두 읽음") { Task { await viewModel.markAllAsRead() } }
                    .disabled(viewModel.unreadCount == 0)
            }
        }
        .task { await viewModel.load() }
        .refreshable { await viewModel.load() }
    }
}

private struct NotificationRow: View {
    let item: AppNotification
    let formatting: DateFormatting

    var body: some View {
        HStack(alignment: .top, spacing: DWSpacing.md) {
            Image(systemName: item.type.icon)
                .font(.body.weight(.medium))
                .foregroundStyle(item.isRead ? DWColor.textTertiary : DWColor.primary)
                .frame(width: 36, height: 36)
                .background(item.isRead ? DWColor.subtle : DWColor.primarySoft, in: Circle())
            VStack(alignment: .leading, spacing: 3) {
                HStack {
                    Text(item.title).dwFont(.subheadline, color: DWColor.textSecondary).fontWeight(.semibold)
                    Spacer()
                    Text(formatting.shortDate(item.createdAt) + " " + formatting.time(item.createdAt))
                        .dwFont(.caption, color: DWColor.textTertiary)
                }
                Text(item.body)
                    .dwFont(.body, color: item.isRead ? DWColor.textSecondary : DWColor.textPrimary)
                    .fontWeight(item.isRead ? .regular : .medium)
            }
        }
        .padding(.vertical, DWSpacing.xs)
        .accessibilityElement(children: .combine)
        .accessibilityLabel((item.isRead ? "" : "읽지 않음, ") + item.title + ", " + item.body)
    }
}

#Preview("알림 센터") {
    PreviewHost { NotificationListView(dependencies: $0.dependencies) }
}
