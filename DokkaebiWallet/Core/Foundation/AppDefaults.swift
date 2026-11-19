import Foundation

/// 서비스 기본값 (PROJECT_PLAN.md: 한국어 / KRW / Asia/Seoul)
public enum AppDefaults {
    public static let serviceName = "도깨비 지갑"
    public static let serviceNameEnglish = "DOKKAEBI WALLET"
    public static let slogan = "우리 가족의 돈과 일상을 담는 지갑"
    public static let currencyCode = "KRW"
    public static let timeZone = TimeZone(identifier: "Asia/Seoul") ?? .current
    public static let locale = Locale(identifier: "ko_KR")
}
