import XCTest

/// 스모크 UI 테스트: 앱 실행 → 5개 탭 이동 → 주요 화면 표시 확인
final class DokkaebiWalletUITests: XCTestCase {
    private var app: XCUIApplication!

    override func setUpWithError() throws {
        continueAfterFailure = false
        app = XCUIApplication()
        app.launchArguments = ["-UITestMock"]
        app.launch()
    }

    func testTabsAreReachable() throws {
        let tabBar = app.tabBars.firstMatch
        XCTAssertTrue(tabBar.waitForExistence(timeout: 10))
        for (title, identifier) in [("가계부", "screen.ledger"), ("지갑", "screen.wallet"),
                                    ("캘린더", "screen.calendar"), ("전체", "screen.more"), ("홈", "screen.home")] {
            tabBar.buttons[title].tap()
            XCTAssertTrue(app.descendants(matching: .any)[identifier].waitForExistence(timeout: 5), "\(title) 화면이 보이지 않습니다")
        }
    }

    func testHomeShowsSampleDataSections() throws {
        XCTAssertTrue(app.descendants(matching: .any)["screen.home"].waitForExistence(timeout: 10))
        XCTAssertTrue(app.staticTexts["샘플 데이터"].firstMatch.exists)
        XCTAssertTrue(app.descendants(matching: .any)["home.summary"].waitForExistence(timeout: 5))
    }

    func testOpenNoticesFromMoreMenu() throws {
        app.tabBars.buttons["전체"].tap()
        app.buttons["more.공지사항"].firstMatch.tap()
        XCTAssertTrue(app.navigationBars["공지사항"].waitForExistence(timeout: 5))
    }

    func testAccessibilityAuditOnHome() throws {
        XCTAssertTrue(app.descendants(matching: .any)["screen.home"].waitForExistence(timeout: 10))
        try app.performAccessibilityAudit(for: [.contrast, .elementDetection, .hitRegion]) { issue in
            // 실패 원인을 CI 로그에서 바로 볼 수 있도록 요소 정보를 남긴다 (문제는 무시하지 않음).
            print("AUDIT-ISSUE: \(issue.auditType) | \(issue.compactDescription) | " +
                  "\(issue.element?.label ?? "-") | \(issue.element?.identifier ?? "-") | \(issue.element?.elementType.rawValue ?? -1)")
            return false
        }
    }
}
