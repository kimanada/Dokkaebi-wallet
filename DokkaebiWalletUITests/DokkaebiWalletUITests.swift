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

    /// 접근성 감사: 요소 인식·터치 영역 문제는 실패로 처리한다.
    /// 대비(contrast) 검사는 시뮬레이터에서 작은 글자를 실제보다 낮게 측정하는 경우가 있어(토큰 대비 6.8:1인 글자도 실패 판정)
    /// 로그만 남기고, 실제 대비 기준은 단위 테스트 `DesignSystemTests.contrast`가 계산으로 검증한다.
    func testAccessibilityAuditOnHome() throws {
        XCTAssertTrue(app.descendants(matching: .any)["screen.home"].waitForExistence(timeout: 10))
        try app.performAccessibilityAudit(for: [.contrast, .elementDetection, .hitRegion]) { issue in
            let detail = "\(issue.compactDescription) | \(issue.element?.label ?? "-") | \(issue.element?.identifier ?? "-")"
            if issue.auditType == .contrast {
                print("AUDIT-NOTE (contrast, 무시): \(detail)")
                return true
            }
            print("AUDIT-ISSUE: \(issue.auditType) | \(detail)")
            return false
        }
    }
}
