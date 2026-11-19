import SwiftUI

/// 거래 상세 (FR-TX-10, 11). 수정·삭제는 이후 단계에서 연결한다.
struct TransactionDetailView: View {
    let row: TransactionRowModel
    @Environment(SessionViewModel.self) private var session
    @Environment(AppRouter.self) private var router
    @State private var alert: DWAlertState?
    private let formatting = DateFormatting()

    var body: some View {
        let transaction = row.transaction
        ScrollView {
            VStack(spacing: DWSpacing.cardGap) {
                VStack(spacing: DWSpacing.md) {
                    CategoryIconView(systemImage: row.icon, color: row.color, size: 56)
                    Text(row.title).dwFont(.title3)
                    Text(row.amountText)
                        .font(DWTypography.amountLarge.font)
                        .foregroundStyle(transaction.type.amountColor)
                    HStack(spacing: DWSpacing.xs) {
                        DWTag(title: transaction.type.displayName)
                        if transaction.type == .expense {
                            DWTag(title: transaction.expenseScope.displayName + " 지출",
                                  foreground: DWColor.primary, background: DWColor.primarySoft)
                        }
                    }
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, DWSpacing.xl)
                .dwCardBackground()

                DWCard {
                    VStack(spacing: 0) {
                        DetailRow(title: "날짜", value: formatting.dayLabel(transaction.occurredAt) + " " + formatting.time(transaction.occurredAt))
                        DetailRow(title: "카테고리", value: row.category?.name ?? "-")
                        DetailRow(title: "결제수단", value: transaction.paymentMethodName ?? "-")
                        DetailRow(title: "실사용자", value: row.spender?.name ?? "-")
                        DetailRow(title: "등록자", value: session.member(id: transaction.createdByID)?.name ?? "-")
                        DetailRow(title: "공개 범위", value: transaction.visibility.displayName)
                        DetailRow(title: "메모", value: transaction.memo ?? "-", isLast: true)
                    }
                }

                if transaction.hasAttachments {
                    DWCard(title: "영수증") {
                        Label("영수증 이미지 보기는 다음 단계에서 지원돼요", systemImage: "photo")
                            .dwFont(.subheadline, color: DWColor.textSecondary)
                    }
                }

                HStack(spacing: DWSpacing.md) {
                    DWButton(title: "수정", systemImage: "pencil", kind: .secondary) {
                        router.present(.comingSoon(feature: "거래 수정"))
                    }
                    DWButton(title: "삭제", systemImage: "trash", kind: .tertiary) {
                        alert = .destructive("이 거래를 삭제할까요?", message: "삭제한 거래는 30일 동안 복구할 수 있어요.") {
                            router.present(.comingSoon(feature: "거래 삭제"))
                        }
                    }
                }
            }
            .dwScreenPadding()
            .padding(.vertical, DWSpacing.lg)
        }
        .dwScreenBackground()
        .dwNavigationStyle("거래 상세", displayMode: .inline)
        .dwAlert($alert)
    }
}

/// 제목-값 한 줄
struct DetailRow: View {
    let title: String
    let value: String
    var isLast = false

    var body: some View {
        VStack(spacing: 0) {
            HStack(alignment: .firstTextBaseline) {
                Text(title).dwFont(.subheadline, color: DWColor.textSecondary)
                Spacer(minLength: DWSpacing.lg)
                Text(value).dwFont(.body).multilineTextAlignment(.trailing)
            }
            .padding(.vertical, DWSpacing.md)
            if !isLast { Divider().overlay(DWColor.border) }
        }
        .accessibilityElement(children: .combine)
    }
}

#Preview("거래 상세") {
    PreviewHost { _ in
        let data = MockData()
        let row = TransactionRowModel.make(data.transactions, categories: data.categories, members: data.members)[0]
        TransactionDetailView(row: row)
    }
}
