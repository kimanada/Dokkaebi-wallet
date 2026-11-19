import Foundation
import Testing
@testable import DokkaebiWallet

@Suite("도메인 모델")
struct ModelTests {
    let me = UUID()

    @Test("공동 지출은 항상 가족 전체 공개 (D2)")
    func sharedMustBeFamily() {
        let tx = LedgerTransaction(type: .expense, amount: 1_000, occurredAt: Fixture.now, categoryID: nil,
                                   expenseScope: .shared, visibility: .private, createdByID: me, spentByID: me)
        #expect(tx.visibility == .family)
        let personal = LedgerTransaction(type: .expense, amount: 1_000, occurredAt: Fixture.now, categoryID: nil,
                                         expenseScope: .personal, visibility: .private, createdByID: me, spentByID: me)
        #expect(personal.visibility == .private)
    }

    @Test("합계: 이체 제외, 공동·개인 지출 분리")
    func summary() {
        let txs = [
            LedgerTransaction(type: .income, amount: 100_000, occurredAt: Fixture.now, categoryID: nil, createdByID: me, spentByID: me),
            LedgerTransaction(type: .expense, amount: 30_000, occurredAt: Fixture.now, categoryID: nil, createdByID: me, spentByID: me),
            LedgerTransaction(type: .expense, amount: 5_000, occurredAt: Fixture.now, categoryID: nil, expenseScope: .personal,
                              createdByID: me, spentByID: me),
            LedgerTransaction(type: .transfer, amount: 70_000, occurredAt: Fixture.now, categoryID: nil, createdByID: me, spentByID: me)
        ]
        let summary = LedgerSummary(transactions: txs)
        #expect(summary.income == 100_000)
        #expect(summary.expense == 35_000)
        #expect(summary.sharedExpense == 30_000)
        #expect(summary.personalExpense == 5_000)
        #expect(summary.balance == 65_000)
    }

    @Test("예산 단계: 80% 경고, 초과 위험", arguments: [
        (Int64(500_000), BudgetStatus.Level.normal), (800_000, .warning), (1_000_000, .warning), (1_000_001, .exceeded)
    ])
    func budgetLevel(spent: Int64, level: BudgetStatus.Level) {
        let status = BudgetStatus(budgetAmount: 1_000_000, spentAmount: spent)
        #expect(status.level == level)
    }

    @Test("예산 잔여·비율")
    func budgetNumbers() {
        let status = BudgetStatus(budgetAmount: 1_500_000, spentAmount: 600_000)
        #expect(status.remaining == 900_000)
        #expect(status.percent == 40)
        #expect(BudgetStatus(budgetAmount: 0, spentAmount: 10).progress == 0)
    }

    @Test("할 일 정렬: 내 할 일 → 마감 임박 → 중요도, 완료 제외")
    func todoSorting() {
        let other = UUID()
        let todos = [
            TodoItem(title: "남의 급한 일", priority: .urgent, dueDate: Fixture.date(2026, 11, 19), assigneeIDs: [other]),
            TodoItem(title: "내 나중 일", dueDate: Fixture.date(2026, 11, 30), assigneeIDs: [me]),
            TodoItem(title: "내 급한 일", dueDate: Fixture.date(2026, 11, 20), assigneeIDs: [me]),
            TodoItem(title: "내 마감 없음", priority: .high, assigneeIDs: [me]),
            TodoItem(title: "완료", status: .done, assigneeIDs: [me])
        ]
        #expect(todos.pendingSorted(for: me).map(\.title) == ["내 급한 일", "내 나중 일", "내 마감 없음", "남의 급한 일"])
    }

    @Test("카드 번호 4자리 띄어쓰기")
    func cardNumber() {
        let card = WalletCard(scope: .personal, brandName: "A", cardNumber: "8801234567890")
        #expect(card.formattedNumber == "8801 2345 6789 0")
        #expect(WalletCard(scope: .personal, brandName: "B").formattedNumber == nil)
    }

    @Test("1차원 바코드 구분")
    func linear() {
        #expect(BarcodeType.ean13.isLinear)
        #expect(!BarcodeType.qr.isLinear)
    }

    @Test("일정이 특정 날짜와 겹치는지")
    func eventOccurs() {
        let event = CalendarEvent(title: "여행", startsAt: Fixture.date(2026, 11, 19, 22), endsAt: Fixture.date(2026, 11, 21, 10))
        #expect(event.occurs(on: Fixture.date(2026, 11, 20), calendar: Fixture.calendar))
        #expect(!event.occurs(on: Fixture.date(2026, 11, 22), calendar: Fixture.calendar))
        #expect(!event.occurs(on: Fixture.date(2026, 11, 18), calendar: Fixture.calendar))
    }

    @Test("팔레트 16색")
    func palette() {
        #expect(PaletteColor.allCases.count == 16)
    }
}
