import Foundation

/// 데이터 출처. 현재 단계에서는 Mock만 지원한다.
public enum DataSourceMode: String, Sendable {
    /// 임시 목업 데이터 (실제 데이터 미연결)
    case mock
    /// Supabase 연동 (이후 단계에서 구현)
    case remote
}

/// 빌드 구성(xcconfig → Info.plist)에서 읽는 앱 설정.
/// service_role 키는 절대 앱에 넣지 않는다 (SECURITY_POLICY.md §1).
public struct AppConfiguration: Sendable {
    public let environmentName: String
    public let supabaseURL: URL?
    public let supabaseAnonKey: String?
    public let dataSourceMode: DataSourceMode

    public init(environmentName: String, supabaseURL: URL?, supabaseAnonKey: String?, dataSourceMode: DataSourceMode) {
        self.environmentName = environmentName
        self.supabaseURL = supabaseURL
        self.supabaseAnonKey = supabaseAnonKey
        self.dataSourceMode = dataSourceMode
    }

    /// Info.plist 값으로 설정을 만든다. Supabase 값이 비어 있으면 Mock 모드로 동작한다.
    public static func load(from info: [String: Any]) -> AppConfiguration {
        func value(_ key: String) -> String? {
            guard let raw = info[key] as? String else { return nil }
            let trimmed = raw.trimmingCharacters(in: .whitespacesAndNewlines)
            return trimmed.isEmpty || trimmed.hasPrefix("$(") ? nil : trimmed
        }
        let url = value("DWSupabaseURL").flatMap(URL.init(string:))
        let key = value("DWSupabaseAnonKey")
        let environment = value("DWEnvironment") ?? "Debug"
        // remote 구현 전까지는 값이 있어도 mock으로 동작한다.
        return AppConfiguration(environmentName: environment, supabaseURL: url, supabaseAnonKey: key, dataSourceMode: .mock)
    }

    public static var current: AppConfiguration {
        load(from: Bundle.main.infoDictionary ?? [:])
    }
}
