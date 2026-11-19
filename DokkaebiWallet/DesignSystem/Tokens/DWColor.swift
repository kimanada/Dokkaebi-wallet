import SwiftUI

/// 색상 토큰 (DESIGN_SYSTEM.md §2).
/// 모든 색은 Asset Catalog의 Color Set(라이트/다크 쌍)에서 불러온다. 코드에 16진수 값을 쓰지 않는다.
/// 값을 바꾸려면 `scripts/generate_assets.py`를 수정하고 다시 실행한다.
enum DWColor {
    // MARK: 배경
    static let canvas = Color("bgCanvas")
    static let surface = Color("bgSurface")
    static let surfaceElevated = Color("bgSurfaceElevated")
    static let subtle = Color("bgSubtle")

    // MARK: 브랜드
    static let primary = Color("brandPrimary")
    static let primaryPressed = Color("brandPrimaryPressed")
    static let onPrimary = Color("brandOnPrimary")
    static let primarySoft = Color("brandPrimarySoft")

    // MARK: 보조 (골드는 장식 전용, 텍스트에 쓰지 않는다)
    static let gold = Color("accentGold")
    static let goldSoft = Color("accentGoldSoft")
    static let beige = Color("accentBeige")
    static let brown = Color("accentBrown")

    // MARK: 텍스트
    static let textPrimary = Color("textPrimary")
    static let textSecondary = Color("textSecondary")
    static let textTertiary = Color("textTertiary")

    // MARK: 테두리
    static let border = Color("borderDefault")
    static let borderStrong = Color("borderStrong")

    // MARK: 의미
    static let income = Color("semanticIncome")
    static let success = Color("semanticSuccess")
    static let warning = Color("semanticWarning")
    static let danger = Color("semanticDanger")
    static let info = Color("semanticInfo")

    static let shadow = Color("shadowColor")

    /// Asset Catalog에 반드시 있어야 하는 색상 이름 목록 (테스트에서 검증)
    static let allAssetNames: [String] = [
        "bgCanvas", "bgSurface", "bgSurfaceElevated", "bgSubtle",
        "brandPrimary", "brandPrimaryPressed", "brandOnPrimary", "brandPrimarySoft",
        "accentGold", "accentGoldSoft", "accentBeige", "accentBrown",
        "textPrimary", "textSecondary", "textTertiary",
        "borderDefault", "borderStrong",
        "semanticIncome", "semanticSuccess", "semanticWarning", "semanticDanger", "semanticInfo",
        "shadowColor", "AccentColor", "LaunchBackground"
    ] + PaletteColor.allCases.map(\.assetName)
}

extension Color {
    /// 팔레트 토큰(카테고리·구성원·카드 색) → 색
    init(palette: PaletteColor) {
        self.init(palette.assetName)
    }
}

extension BudgetStatus.Level {
    var color: Color {
        switch self {
        case .normal: return DWColor.primary
        case .warning: return DWColor.warning
        case .exceeded: return DWColor.danger
        }
    }
}

extension TransactionType {
    /// 수입은 초록, 지출은 기본 텍스트색 (빨간색을 쓰지 않는다), 이체는 보조색
    var amountColor: Color {
        switch self {
        case .income: return DWColor.income
        case .expense: return DWColor.textPrimary
        case .transfer: return DWColor.textSecondary
        }
    }
}
