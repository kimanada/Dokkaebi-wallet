import Foundation
@testable import DokkaebiWallet

/// 테스트 공통 고정값. 날짜는 2026-11-19 (목) 12:00 KST로 고정한다.
enum Fixture {
    static let timeZone = TimeZone(identifier: "Asia/Seoul")!

    static var calendar: Calendar {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = timeZone
        calendar.locale = Locale(identifier: "ko_KR")
        return calendar
    }

    static func date(_ year: Int, _ month: Int, _ day: Int, _ hour: Int = 12, _ minute: Int = 0) -> Date {
        calendar.date(from: DateComponents(year: year, month: month, day: day, hour: hour, minute: minute))!
    }

    static let now = date(2026, 11, 19)

    static func mockData() -> MockData {
        MockData(now: now, calendar: calendar)
    }

    static func dependencies(data: MockData = mockData(), behavior: MockBehavior = .instant) -> AppDependencies {
        .mock(data: data, behavior: behavior)
    }
}
