import Foundation

/// 원화(KRW) 금액 표시 규칙 (DESIGN_SYSTEM.md §3).
/// 금액은 원 단위 정수(`Int64`)로 다룬다 (PROJECT_PLAN.md D4).
public enum MoneyFormatter {
    public enum Sign {
        /// 부호 없음 (지출, 합계)
        case none
        /// 항상 "+" 표시 (수입)
        case plus
        /// 항상 "-" 표시 (차감)
        case minus
    }

    private static let grouping: NumberFormatter = {
        let formatter = NumberFormatter()
        formatter.locale = Locale(identifier: "ko_KR")
        formatter.numberStyle = .decimal
        formatter.usesGroupingSeparator = true
        formatter.groupingSeparator = ","
        formatter.groupingSize = 3
        formatter.maximumFractionDigits = 0
        return formatter
    }()

    /// 숫자만 천 단위 구분 기호를 붙여 표시한다. 예: `32000` → `"32,000"`
    public static func decimal(_ amount: Int64) -> String {
        grouping.string(from: NSNumber(value: amount)) ?? String(amount)
    }

    /// 예: `32000` → `"32,000원"`, `.plus` → `"+32,000원"`
    public static func won(_ amount: Int64, sign: Sign = .none) -> String {
        let body = decimal(abs(amount)) + "원"
        switch sign {
        case .none: return amount < 0 ? "-" + body : body
        case .plus: return "+" + body
        case .minus: return "-" + body
        }
    }

    /// 차트 축과 요약에 쓰는 짧은 표기. 예: `12_500_000` → `"1,250만"`, `250_000_000` → `"2.5억"`
    public static func compact(_ amount: Int64) -> String {
        let value = abs(amount)
        let prefix = amount < 0 ? "-" : ""
        if value >= 100_000_000 {
            let eok = Double(value) / 100_000_000
            let rounded = (eok * 10).rounded() / 10
            let text = rounded == rounded.rounded() ? String(Int64(rounded)) : String(format: "%.1f", rounded)
            return prefix + text + "억"
        }
        if value >= 10_000 {
            return prefix + decimal(value / 10_000) + "만"
        }
        return prefix + decimal(value)
    }

    /// 사용자 입력 문자열에서 숫자만 추출한다. 상한(999,999,999,999원)을 넘으면 nil.
    public static func parse(_ input: String) -> Int64? {
        let digits = input.filter(\.isNumber)
        guard !digits.isEmpty, digits.count <= 12, let value = Int64(digits) else { return nil }
        return value
    }

    public static let maximumAmount: Int64 = 999_999_999_999
}
