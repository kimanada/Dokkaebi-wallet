import Foundation
import Testing
@testable import DokkaebiWallet

@Suite("금액 표시 MoneyFormatter")
struct MoneyFormatterTests {
    @Test("천 단위 구분 기호와 원 단위", arguments: [
        (Int64(0), "0원"), (32_000, "32,000원"), (1_234_567, "1,234,567원"), (-5_000, "-5,000원")
    ])
    func won(amount: Int64, expected: String) {
        #expect(MoneyFormatter.won(amount) == expected)
    }

    @Test("수입은 + 부호")
    func plusSign() {
        #expect(MoneyFormatter.won(50_000, sign: .plus) == "+50,000원")
        #expect(MoneyFormatter.won(50_000, sign: .minus) == "-50,000원")
    }

    @Test("짧은 표기 (만·억)", arguments: [
        (Int64(9_999), "9,999"), (10_000, "1만"), (12_500_000, "1,250만"), (100_000_000, "1억"), (250_000_000, "2.5억")
    ])
    func compact(amount: Int64, expected: String) {
        #expect(MoneyFormatter.compact(amount) == expected)
    }

    @Test("입력 문자열 파싱과 상한")
    func parse() {
        #expect(MoneyFormatter.parse("32,000원") == 32_000)
        #expect(MoneyFormatter.parse("") == nil)
        #expect(MoneyFormatter.parse("abc") == nil)
        #expect(MoneyFormatter.parse("999999999999") == MoneyFormatter.maximumAmount)
        #expect(MoneyFormatter.parse("1000000000000") == nil)
    }
}

@Suite("가계부 기간 BudgetPeriod")
struct BudgetPeriodTests {
    let calendar = Fixture.calendar

    @Test("월 시작일 1일: 해당 월 1일 ~ 다음 달 1일")
    func firstDay() {
        let period = BudgetPeriod.containing(Fixture.date(2026, 11, 19), monthStartDay: 1, calendar: calendar)
        #expect(period.start == calendar.startOfDay(for: Fixture.date(2026, 11, 1)))
        #expect(period.endExclusive == calendar.startOfDay(for: Fixture.date(2026, 12, 1)))
    }

    @Test("월 시작일 25일: 시작일 이전 날짜는 지난달 25일부터")
    func beforeStartDay() {
        let period = BudgetPeriod.containing(Fixture.date(2026, 11, 19), monthStartDay: 25, calendar: calendar)
        #expect(period.start == calendar.startOfDay(for: Fixture.date(2026, 10, 25)))
        #expect(period.endExclusive == calendar.startOfDay(for: Fixture.date(2026, 11, 25)))
        #expect(calendar.isDate(period.lastDay(calendar: calendar), inSameDayAs: Fixture.date(2026, 11, 24)))
    }

    @Test("월 시작일 당일은 새 기간에 포함")
    func onStartDay() {
        let period = BudgetPeriod.containing(Fixture.date(2026, 11, 25, 0, 0), monthStartDay: 25, calendar: calendar)
        #expect(period.start == calendar.startOfDay(for: Fixture.date(2026, 11, 25)))
    }

    @Test("1월 이전 기간은 전년도 12월")
    func yearBoundary() {
        let period = BudgetPeriod.containing(Fixture.date(2027, 1, 10), monthStartDay: 25, calendar: calendar)
        #expect(period.start == calendar.startOfDay(for: Fixture.date(2026, 12, 25)))
        let previous = period.previous(calendar: calendar)
        #expect(previous.start == calendar.startOfDay(for: Fixture.date(2026, 11, 25)))
        #expect(previous.endExclusive == period.start)
    }

    @Test("범위를 벗어난 시작일은 1~28로 보정")
    func clamp() {
        let period = BudgetPeriod.containing(Fixture.date(2026, 2, 27), monthStartDay: 31, calendar: calendar)
        #expect(period.start == calendar.startOfDay(for: Fixture.date(2026, 1, 28)))
    }

    @Test("contains는 시작 포함, 끝 미포함")
    func contains() {
        let period = BudgetPeriod.containing(Fixture.now, monthStartDay: 1, calendar: calendar)
        #expect(period.contains(period.start))
        #expect(!period.contains(period.endExclusive))
    }
}

@Suite("날짜 표시 DateFormatting")
struct DateFormattingTests {
    let formatting = DateFormatting(timeZone: Fixture.timeZone)

    @Test("같은 해는 연도 생략, 다른 해는 연도 표시")
    func dayLabel() {
        #expect(formatting.dayLabel(Fixture.date(2026, 11, 19), relativeTo: Fixture.now) == "11월 19일 (목)")
        #expect(formatting.dayLabel(Fixture.date(2025, 11, 19), relativeTo: Fixture.now) == "2025년 11월 19일 (수)")
    }

    @Test("오전·오후 시간")
    func time() {
        #expect(formatting.time(Fixture.date(2026, 11, 19, 15, 20)) == "오후 3:20")
        #expect(formatting.time(Fixture.date(2026, 11, 19, 9, 5)) == "오전 9:05")
    }

    @Test("월 제목")
    func month() {
        #expect(formatting.monthTitle(Fixture.now) == "2026년 11월")
    }

    @Test("D-day")
    func dDay() {
        #expect(formatting.dDay(Fixture.date(2026, 11, 19, 23), from: Fixture.now) == "D-Day")
        #expect(formatting.dDay(Fixture.date(2026, 11, 22), from: Fixture.now) == "D-3")
        #expect(formatting.dDay(Fixture.date(2026, 11, 17), from: Fixture.now) == "D+2")
    }
}

@Suite("오류 문구 AppError")
struct AppErrorTests {
    @Test("재시도 가능 여부")
    func retryable() {
        #expect(AppError.network(.offline).isRetryable)
        #expect(AppError.server(code: "500").isRetryable)
        #expect(!AppError.forbidden.isRetryable)
        #expect(!AppError.validation(message: "x").isRetryable)
    }

    @Test("검증 오류는 전달한 메시지를 그대로 보여준다")
    func validationMessage() {
        #expect(AppError.validation(message: "공동 지출은 가족 공개만 가능해요").message == "공동 지출은 가족 공개만 가능해요")
    }

    @Test("임의 오류 변환")
    func wrap() {
        struct Sample: Error {}
        #expect(AppError.wrap(AppError.notFound) == .notFound)
        if case .unknown = AppError.wrap(Sample()) {} else { Issue.record("unknown으로 변환되어야 한다") }
    }
}

@Suite("앱 설정 AppConfiguration")
struct AppConfigurationTests {
    @Test("치환되지 않은 빌드 변수와 빈 값은 nil")
    func emptyValues() {
        let config = AppConfiguration.load(from: ["DWSupabaseURL": "$(SUPABASE_URL)", "DWSupabaseAnonKey": " "])
        #expect(config.supabaseURL == nil)
        #expect(config.supabaseAnonKey == nil)
        #expect(config.environmentName == "Debug")
        #expect(config.dataSourceMode == .mock)
    }

    @Test("값이 있으면 읽는다")
    func values() {
        let config = AppConfiguration.load(from: ["DWSupabaseURL": "https://example.supabase.co",
                                                  "DWSupabaseAnonKey": "anon", "DWEnvironment": "Release"])
        #expect(config.supabaseURL?.host == "example.supabase.co")
        #expect(config.supabaseAnonKey == "anon")
        #expect(config.environmentName == "Release")
    }
}
