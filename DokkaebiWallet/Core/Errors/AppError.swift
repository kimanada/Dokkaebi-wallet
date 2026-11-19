import Foundation

/// 앱 전체에서 쓰는 오류 모델 (APP_STRUCTURE.md §9).
public enum AppError: Error, Equatable, Sendable {
    public enum NetworkReason: Equatable, Sendable {
        case offline, timeout, serverUnreachable
    }

    case network(NetworkReason)
    case unauthorized
    case forbidden
    case notFound
    case conflict(serverVersion: Int)
    case validation(message: String)
    case rateLimited
    case server(code: String?)
    case unknown(description: String)

    /// 사용자에게 보여줄 문구 (해요체, 원인과 해결책을 함께)
    public var title: String {
        switch self {
        case .network: return "잠시 연결이 원활하지 않아요"
        case .unauthorized: return "다시 로그인해 주세요"
        case .forbidden: return "이 항목을 볼 수 있는 권한이 없어요"
        case .notFound: return "더 이상 볼 수 없는 항목이에요"
        case .conflict: return "다른 구성원이 먼저 수정했어요"
        case .validation: return "입력 내용을 확인해 주세요"
        case .rateLimited: return "요청이 너무 많아요"
        case .server, .unknown: return "문제가 발생했어요"
        }
    }

    public var message: String {
        switch self {
        case .network(.offline): return "인터넷 연결을 확인해 주세요. 연결되면 자동으로 저장돼요."
        case .network: return "잠시 후 다시 시도해 주세요."
        case .unauthorized: return "보안을 위해 로그인이 만료되었어요."
        case .forbidden: return "가족 관리자에게 권한을 확인해 주세요."
        case .notFound: return "삭제되었거나 공개 범위가 바뀌었을 수 있어요."
        case .conflict: return "최신 내용을 불러온 뒤 다시 저장해 주세요."
        case .validation(let message): return message
        case .rateLimited: return "잠시 기다린 뒤 다시 시도해 주세요."
        case .server(let code): return "잠시 후 다시 시도해 주세요." + (code.map { " (오류 코드 \($0))" } ?? "")
        case .unknown: return "잠시 후 다시 시도해 주세요."
        }
    }

    /// 재시도 버튼을 보여줄지 여부
    public var isRetryable: Bool {
        switch self {
        case .network, .server, .unknown, .rateLimited: return true
        default: return false
        }
    }
}
