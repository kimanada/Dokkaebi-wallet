import Foundation

/// 임시 목업 데이터. 실제 데이터가 연결되기 전까지 UI 구성에만 쓴다.
/// 날짜는 `now` 기준 상대값으로 만들어 항상 "이번 달" 데이터처럼 보이게 한다.
public struct MockData: Sendable {
    public let now: Date
    public let calendar: Calendar

    public let groups: [FamilyGroup]
    public let members: [FamilyMember]
    public let categories: [LedgerCategory]
    public let transactions: [LedgerTransaction]
    public let budget: Budget
    public let events: [CalendarEvent]
    public let notices: [Notice]
    public let todos: [TodoItem]
    public let cards: [WalletCard]
    public let notifications: [AppNotification]

    public var me: FamilyMember { members[0] }

    // 고정 ID: 테스트와 Preview에서 재현 가능하도록
    public static let homeGroupID = UUID(uuidString: "00000000-0000-0000-0000-0000000000A1")!
    public static let parentsGroupID = UUID(uuidString: "00000000-0000-0000-0000-0000000000A2")!

    public init(now: Date = Date(), calendar: Calendar = DateFormatting().calendar) {
        self.now = now
        self.calendar = calendar

        func day(_ offset: Int, _ hour: Int = 12, _ minute: Int = 0) -> Date {
            let base = calendar.startOfDay(for: now)
            let shifted = calendar.date(byAdding: .day, value: offset, to: base) ?? base
            return calendar.date(bySettingHour: hour, minute: minute, second: 0, of: shifted) ?? shifted
        }

        groups = [
            FamilyGroup(id: Self.homeGroupID, name: "우리집", myRole: .owner, memberCount: 4),
            FamilyGroup(id: Self.parentsGroupID, name: "본가 가족", monthStartDay: 25, myRole: .member, memberCount: 5)
        ]

        let me = FamilyMember(displayName: "김지우", nickname: "지우", role: .owner, color: .pine, isMe: true)
        let partner = FamilyMember(displayName: "박서연", nickname: "서연", role: .admin, color: .indigo)
        let child = FamilyMember(displayName: "김하늘", nickname: "하늘", role: .member, color: .ochre)
        let grandma = FamilyMember(displayName: "이순자", nickname: "할머니", role: .member, color: .pomegranate)
        members = [me, partner, child, grandma]

        let food = LedgerCategory(kind: .expense, name: "식비", icon: "fork.knife", color: .maple, sortOrder: 0)
        let cafe = LedgerCategory(kind: .expense, name: "카페·간식", icon: "cup.and.saucer", color: .chestnut, sortOrder: 1)
        let grocery = LedgerCategory(kind: .expense, name: "장보기", icon: "cart", color: .moss, sortOrder: 2)
        let housing = LedgerCategory(kind: .expense, name: "주거·관리비", icon: "house", color: .indigo, sortOrder: 3)
        let transport = LedgerCategory(kind: .expense, name: "교통", icon: "bus", color: .sky, sortOrder: 4)
        let education = LedgerCategory(kind: .expense, name: "교육", icon: "book", color: .plum, sortOrder: 5)
        let culture = LedgerCategory(kind: .expense, name: "문화·여가", icon: "theatermasks", color: .azalea, sortOrder: 6)
        let salary = LedgerCategory(kind: .income, name: "급여", icon: "banknote", color: .pine, sortOrder: 0)
        let allowance = LedgerCategory(kind: .income, name: "용돈", icon: "gift", color: .gold, sortOrder: 1)
        categories = [food, cafe, grocery, housing, transport, education, culture, salary, allowance]

        transactions = [
            LedgerTransaction(type: .expense, amount: 32_000, occurredAt: day(0, 12, 40), categoryID: food.id,
                              merchant: "동네 국밥집", memo: "가족 점심", paymentMethodName: "생활비 카드",
                              createdByID: me.id, spentByID: me.id, hasAttachments: true),
            LedgerTransaction(type: .expense, amount: 5_800, occurredAt: day(0, 9, 10), categoryID: cafe.id,
                              merchant: "모퉁이 커피", paymentMethodName: "개인 체크카드", expenseScope: .personal,
                              visibility: .private, createdByID: me.id, spentByID: me.id),
            LedgerTransaction(type: .expense, amount: 87_400, occurredAt: day(-1, 19, 5), categoryID: grocery.id,
                              merchant: "초록마트", memo: "주말 장보기", paymentMethodName: "생활비 카드",
                              createdByID: partner.id, spentByID: partner.id),
            LedgerTransaction(type: .expense, amount: 1_450, occurredAt: day(-1, 8, 20), categoryID: transport.id,
                              merchant: "버스", paymentMethodName: "교통카드", expenseScope: .personal,
                              createdByID: child.id, spentByID: child.id),
            LedgerTransaction(type: .income, amount: 3_800_000, occurredAt: day(-3, 9, 0), categoryID: salary.id,
                              merchant: "11월 급여", paymentMethodName: "급여 통장", createdByID: me.id, spentByID: me.id),
            LedgerTransaction(type: .expense, amount: 245_000, occurredAt: day(-4, 10, 0), categoryID: housing.id,
                              merchant: "아파트 관리비", paymentMethodName: "생활비 통장",
                              createdByID: partner.id, spentByID: partner.id),
            LedgerTransaction(type: .expense, amount: 180_000, occurredAt: day(-5, 16, 0), categoryID: education.id,
                              merchant: "피아노 학원", paymentMethodName: "생활비 카드",
                              createdByID: me.id, spentByID: child.id),
            LedgerTransaction(type: .income, amount: 50_000, occurredAt: day(-6, 18, 0), categoryID: allowance.id,
                              merchant: "할머니 용돈", expenseScope: .personal, visibility: .family,
                              createdByID: child.id, spentByID: child.id),
            LedgerTransaction(type: .expense, amount: 42_000, occurredAt: day(-7, 20, 30), categoryID: culture.id,
                              merchant: "영화관", memo: "가족 영화", paymentMethodName: "생활비 카드",
                              createdByID: partner.id, spentByID: partner.id),
            LedgerTransaction(type: .transfer, amount: 300_000, occurredAt: day(-8, 9, 0), categoryID: nil,
                              merchant: "생활비 통장으로 이체", paymentMethodName: "급여 통장",
                              createdByID: me.id, spentByID: me.id)
        ]

        budget = Budget(scope: .family, totalAmount: 1_500_000)

        events = [
            CalendarEvent(title: "하늘이 학부모 상담", startsAt: day(0, 16, 0), endsAt: day(0, 17, 0),
                          location: "하늘초등학교", participantIDs: [me.id, partner.id], color: .plum),
            CalendarEvent(title: "가족 저녁 식사", startsAt: day(0, 19, 0), endsAt: day(0, 20, 30),
                          location: "집", participantIDs: members.map(\.id), color: .pine),
            CalendarEvent(title: "할머니 병원 정기 검진", startsAt: day(2, 10, 0), endsAt: day(2, 11, 0),
                          location: "서울 내과", participantIDs: [partner.id, grandma.id], color: .pomegranate),
            CalendarEvent(title: "분리수거의 날", startsAt: day(3), endsAt: day(3), isAllDay: true, color: .moss),
            CalendarEvent(title: "할머니 생신", startsAt: day(9), endsAt: day(9), isAllDay: true,
                          participantIDs: members.map(\.id), color: .gold)
        ]

        notices = [
            Notice(title: "이번 달 생활비 정산 안내", body: "말일까지 공동 지출 영수증을 첨부해 주세요.",
                   authorID: me.id, createdAt: day(-2, 21, 0), isPinned: true, readCount: 3, memberCount: 4, isReadByMe: true),
            Notice(title: "할머니 생신 선물 의견 모아요", body: "원하는 선물이 있으면 댓글 대신 이 공지에 남겨 주세요.",
                   authorID: partner.id, createdAt: day(-1, 20, 15), readCount: 2, memberCount: 4, isReadByMe: false),
            Notice(title: "주말 대청소", body: "토요일 오전 10시에 함께 청소해요.",
                   authorID: partner.id, createdAt: day(-6, 9, 0), readCount: 4, memberCount: 4, isReadByMe: true)
        ]

        todos = [
            TodoItem(title: "관리비 자동이체 확인", priority: .high, dueDate: day(0, 18), assigneeIDs: [me.id]),
            TodoItem(title: "할머니 생신 케이크 예약", status: .inProgress, priority: .normal, dueDate: day(5), assigneeIDs: [me.id, partner.id]),
            TodoItem(title: "분리수거", priority: .normal, dueDate: day(3), assigneeIDs: [child.id]),
            TodoItem(title: "겨울 이불 세탁", priority: .low, assigneeIDs: [partner.id]),
            TodoItem(title: "자동차 보험 갱신", priority: .urgent, dueDate: day(1), assigneeIDs: [partner.id]),
            TodoItem(title: "프린터 잉크 주문", status: .done, priority: .low, assigneeIDs: [me.id])
        ]

        cards = [
            WalletCard(scope: .family, brandName: "초록마트", cardName: "가족 멤버십", cardNumber: "8801234567890",
                       barcodeValue: "8801234567890", barcodeType: .ean13, memo: "주말 10% 할인", color: .moss, isFavorite: true),
            WalletCard(scope: .personal, brandName: "모퉁이 커피", cardName: "스탬프 카드", barcodeValue: "MOTUNGI-2026-7781",
                       barcodeType: .qr, color: .chestnut, isFavorite: true),
            WalletCard(scope: .family, brandName: "한빛 주유소", cardName: "포인트 카드", cardNumber: "2026111900042",
                       barcodeValue: "2026111900042", barcodeType: .code128, color: .indigo),
            WalletCard(scope: .personal, brandName: "책방 오늘", cardName: "회원 카드", barcodeValue: "BOOK-ON-0091",
                       barcodeType: .code128, memo: "생일 쿠폰 12월", color: .plum),
            WalletCard(scope: .family, brandName: "동네 빵집", cardName: "가족 쿠폰", barcodeValue: "BREAD-FAMILY-15",
                       barcodeType: .qr, color: .ochre)
        ]

        notifications = [
            AppNotification(type: .transactionCreated, title: "새 공동 지출", body: "서연님이 장보기 87,400원을 기록했어요",
                            createdAt: day(-1, 19, 6)),
            AppNotification(type: .noticeCreated, title: "새 공지", body: "할머니 생신 선물 의견 모아요",
                            createdAt: day(-1, 20, 15)),
            AppNotification(type: .budgetWarning, title: "예산 알림", body: "이번 달 가족 예산의 80%에 가까워지고 있어요",
                            createdAt: day(-2, 9, 0), isRead: true),
            AppNotification(type: .taskAssigned, title: "할 일 배정", body: "서연님이 '할머니 생신 케이크 예약'을 함께 맡겼어요",
                            createdAt: day(-3, 14, 0), isRead: true),
            AppNotification(type: .eventCreated, title: "새 일정", body: "할머니 병원 정기 검진",
                            createdAt: day(-4, 11, 0), isRead: true)
        ]
    }

    public func category(id: UUID?) -> LedgerCategory? {
        guard let id else { return nil }
        return categories.first { $0.id == id }
    }

    public func member(id: UUID) -> FamilyMember? {
        members.first { $0.id == id }
    }
}
