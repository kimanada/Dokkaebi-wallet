import SwiftUI

/// 할 일 목록 (FR-TASK)
struct TodoListView: View {
    @Environment(SessionViewModel.self) private var session
    @Environment(AppRouter.self) private var router
    @State private var viewModel: TodoViewModel
    @State private var toast: DWToast?

    init(dependencies: AppDependencies) {
        _viewModel = State(initialValue: TodoViewModel(dependencies: dependencies))
    }

    var body: some View {
        @Bindable var viewModel = viewModel
        ScrollView {
            VStack(alignment: .leading, spacing: DWSpacing.md) {
                if viewModel.isUsingMockData { MockDataBanner() }
                DWSegmentedControl(options: TodoListFilter.allCases, selection: $viewModel.filter) { $0.displayName }
                DWStateView(state: viewModel.state, retry: { Task { await reload() } }) {
                    DWEmptyState(systemImage: "checkmark.seal",
                                 title: viewModel.filter == .done ? "완료한 할 일이 없어요" : "모두 끝냈어요!")
                        .dwCardBackground()
                } content: { items in
                    VStack(spacing: 0) {
                        ForEach(items) { item in
                            TodoRowView(item: item, members: session.members) {
                                Task {
                                    await viewModel.toggleDone(item)
                                    if !item.isDone {
                                        toast = DWToast(message: "'\(item.title)' 완료!", systemImage: "checkmark.circle.fill")
                                    }
                                }
                            }
                            if item.id != items.last?.id { Divider().overlay(DWColor.border).padding(.leading, 44) }
                        }
                    }
                    .padding(.horizontal, DWSpacing.lg)
                    .dwCardBackground()
                }
            }
            .dwScreenPadding()
            .padding(.bottom, DWSpacing.xxl)
        }
        .dwScreenBackground()
        .dwNavigationStyle("할 일", displayMode: .inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button { router.present(.comingSoon(feature: "할 일 등록")) } label: { Image(systemName: "plus.circle.fill") }
                    .accessibilityLabel("할 일 추가")
            }
        }
        .dwToast($toast)
        .task(id: session.groupRevision) { await reload() }
    }

    private func reload() async {
        guard let group = session.currentGroup else { return }
        await viewModel.load(groupID: group.id, meID: session.me?.id)
    }
}

/// 할 일 한 줄 (DESIGN_SYSTEM.md §5 TaskRow)
struct TodoRowView: View {
    let item: TodoItem
    let members: [FamilyMember]
    let onToggle: () -> Void
    private let formatting = DateFormatting()

    var body: some View {
        HStack(spacing: DWSpacing.md) {
            Button(action: onToggle) {
                Image(systemName: item.isDone ? "checkmark.circle.fill" : "circle")
                    .font(.title2)
                    .foregroundStyle(item.isDone ? DWColor.primary : DWColor.borderStrong)
                    .frame(width: DWSpacing.minTouchTarget, height: DWSpacing.minTouchTarget)
            }
            .buttonStyle(.plain)
            .accessibilityLabel(item.isDone ? "완료 취소" : "완료로 표시")
            .sensoryFeedback(.success, trigger: item.isDone) { _, newValue in newValue }

            VStack(alignment: .leading, spacing: 3) {
                Text(item.title)
                    .dwFont(.body, color: item.isDone ? DWColor.textTertiary : DWColor.textPrimary)
                    .strikethrough(item.isDone, color: DWColor.textTertiary)
                HStack(spacing: DWSpacing.xs) {
                    if item.priority >= .high {
                        DWTag(title: item.priority.displayName, foreground: DWColor.danger, background: DWColor.danger.opacity(0.12))
                    }
                    if item.status == .inProgress {
                        DWTag(title: item.status.displayName, foreground: DWColor.info, background: DWColor.info.opacity(0.12))
                    }
                    if let due = item.dueDate, !item.isDone {
                        let label = formatting.dDay(due)
                        DueTag(text: label, isUrgent: label == "D-Day" || label.hasPrefix("D+"))
                    }
                }
            }
            Spacer(minLength: 0)
            DWAvatarStack(members: members.filter { item.assigneeIDs.contains($0.id) }, size: 22)
        }
        .padding(.vertical, DWSpacing.xs)
        .accessibilityElement(children: .combine)
    }
}

#Preview("할 일") {
    PreviewHost { TodoListView(dependencies: $0.dependencies) }
}
