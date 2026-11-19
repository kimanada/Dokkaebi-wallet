import SwiftUI

/// 거래 목록 한 줄 (DESIGN_SYSTEM.md §5 TransactionRow)
struct TransactionRowView: View {
    let row: TransactionRowModel
    var showsTime = false
    var formatting = DateFormatting()

    var body: some View {
        HStack(spacing: DWSpacing.md) {
            CategoryIconView(systemImage: row.icon, color: row.color)
            VStack(alignment: .leading, spacing: 3) {
                HStack(spacing: DWSpacing.xs) {
                    Text(row.title).dwFont(.headline).lineLimit(1)
                    VisibilityBadge(visibility: row.transaction.visibility)
                    if row.transaction.hasAttachments {
                        Image(systemName: "paperclip")
                            .font(.caption2)
                            .foregroundStyle(DWColor.textTertiary)
                            .accessibilityLabel("영수증 첨부")
                    }
                }
                HStack(spacing: DWSpacing.xs) {
                    if row.transaction.type == .expense {
                        scopeTag
                    }
                    Text(subtitle).dwFont(.footnote, color: DWColor.textSecondary).lineLimit(1)
                }
            }
            Spacer(minLength: DWSpacing.sm)
            VStack(alignment: .trailing, spacing: 3) {
                Text(row.amountText)
                    .font(DWTypography.amountRow.font)
                    .foregroundStyle(row.transaction.type.amountColor)
                if let spender = row.spender {
                    DWAvatar(member: spender, size: 18)
                }
            }
        }
        .padding(.vertical, DWSpacing.xs)
        .frame(minHeight: 56)
        .contentShape(Rectangle())
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(accessibilityText)
    }

    private var subtitle: String {
        guard showsTime else { return row.subtitle }
        return [formatting.time(row.transaction.occurredAt), row.subtitle].joined(separator: " · ")
    }

    @ViewBuilder
    private var scopeTag: some View {
        switch row.transaction.expenseScope {
        case .shared: DWTag(title: "공동", foreground: DWColor.primary, background: DWColor.primarySoft)
        case .personal: DWTag(title: "개인")
        }
    }

    private var accessibilityText: String {
        var parts = [row.title, row.amountText, row.transaction.type.displayName]
        if let category = row.category?.name { parts.append(category) }
        if row.transaction.type == .expense { parts.append(row.transaction.expenseScope.displayName + " 지출") }
        if row.transaction.visibility != .family { parts.append(row.transaction.visibility.displayName) }
        if let spender = row.spender { parts.append("사용자 \(spender.name)") }
        return parts.joined(separator: ", ")
    }
}

#Preview("거래 행") {
    let data = MockData()
    let rows = TransactionRowModel.make(data.transactions, categories: data.categories, members: data.members)
    return VStack(spacing: 0) {
        ForEach(rows) { TransactionRowView(row: $0, showsTime: true) }
    }
    .padding()
    .dwCardBackground()
    .padding()
    .background(DWColor.canvas)
}
