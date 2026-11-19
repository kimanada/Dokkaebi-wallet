import Foundation

/// 화면 상태 (APP_STRUCTURE.md §4)
public enum ViewState<Value> {
    case idle
    case loading
    case loaded(Value)
    case empty
    case failed(AppError)

    public var value: Value? {
        if case .loaded(let value) = self { return value }
        return nil
    }

    public var isLoading: Bool {
        if case .loading = self { return true }
        return false
    }

    public var error: AppError? {
        if case .failed(let error) = self { return error }
        return nil
    }
}

extension ViewState: Equatable where Value: Equatable {}
extension ViewState: Sendable where Value: Sendable {}
