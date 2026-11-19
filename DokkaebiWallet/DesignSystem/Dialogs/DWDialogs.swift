import SwiftUI

/// 알림창(Alert) 정의. 화면에서는 `.dwAlert($state)`로 띄운다.
struct DWAlertState: Identifiable {
    struct Action {
        let title: String
        var role: ButtonRole?
        var handler: () -> Void = {}
    }

    let id = UUID()
    let title: String
    var message: String?
    var primary: Action
    var secondary: Action?

    /// 확인 버튼 하나짜리 안내
    static func notice(_ title: String, message: String? = nil) -> DWAlertState {
        DWAlertState(title: title, message: message, primary: Action(title: "확인"))
    }

    /// 오류 안내
    static func error(_ error: AppError, retry: (() -> Void)? = nil) -> DWAlertState {
        DWAlertState(
            title: error.title,
            message: error.message,
            primary: retry.map { Action(title: "다시 시도", handler: $0) } ?? Action(title: "확인"),
            secondary: retry == nil ? nil : Action(title: "닫기", role: .cancel)
        )
    }

    /// 삭제 등 파괴적 동작 확인
    static func destructive(_ title: String, message: String? = nil, confirmTitle: String = "삭제",
                            onConfirm: @escaping () -> Void) -> DWAlertState {
        DWAlertState(title: title, message: message,
                     primary: Action(title: confirmTitle, role: .destructive, handler: onConfirm),
                     secondary: Action(title: "취소", role: .cancel))
    }
}

/// 하단 확인 시트(Confirmation Dialog) 정의
struct DWConfirmationState: Identifiable {
    struct Option: Identifiable {
        let id = UUID()
        let title: String
        var role: ButtonRole?
        let handler: () -> Void
    }

    let id = UUID()
    let title: String
    var message: String?
    let options: [Option]
}

extension View {
    func dwAlert(_ state: Binding<DWAlertState?>) -> some View {
        alert(
            state.wrappedValue?.title ?? "",
            isPresented: Binding(get: { state.wrappedValue != nil }, set: { if !$0 { state.wrappedValue = nil } }),
            presenting: state.wrappedValue
        ) { alert in
            Button(alert.primary.title, role: alert.primary.role, action: alert.primary.handler)
            if let secondary = alert.secondary {
                Button(secondary.title, role: secondary.role, action: secondary.handler)
            }
        } message: { alert in
            if let message = alert.message { Text(message) }
        }
    }

    func dwConfirmationDialog(_ state: Binding<DWConfirmationState?>) -> some View {
        confirmationDialog(
            state.wrappedValue?.title ?? "",
            isPresented: Binding(get: { state.wrappedValue != nil }, set: { if !$0 { state.wrappedValue = nil } }),
            titleVisibility: .visible,
            presenting: state.wrappedValue
        ) { dialog in
            ForEach(dialog.options) { option in
                Button(option.title, role: option.role, action: option.handler)
            }
            Button("취소", role: .cancel) {}
        } message: { dialog in
            if let message = dialog.message { Text(message) }
        }
    }
}

#Preview("알림창") {
    struct Demo: View {
        @State private var alert: DWAlertState?
        @State private var dialog: DWConfirmationState?
        @State private var toast: DWToast?
        var body: some View {
            VStack(spacing: DWSpacing.md) {
                DWButton(title: "삭제 확인 알림", kind: .destructive) {
                    alert = .destructive("거래를 삭제할까요?", message: "삭제한 거래는 30일 동안 복구할 수 있어요.") {
                        toast = DWToast(message: "삭제했어요", systemImage: "trash", actionTitle: "실행 취소", action: {})
                    }
                }
                DWButton(title: "오류 알림", kind: .secondary) { alert = .error(.network(.offline), retry: {}) }
                DWButton(title: "확인 시트", kind: .secondary) {
                    dialog = DWConfirmationState(title: "카드 추가 방법", options: [
                        .init(title: "카메라로 스캔") {}, .init(title: "사진에서 가져오기") {}, .init(title: "직접 입력") {}
                    ])
                }
            }
            .padding()
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(DWColor.canvas)
            .dwAlert($alert)
            .dwConfirmationDialog($dialog)
            .dwToast($toast)
        }
    }
    return Demo()
}
