import SwiftUI

/// 텍스트 입력 필드 (DESIGN_SYSTEM.md §5).
/// 포커스 시 딥그린 테두리, 오류가 있으면 위험 색 테두리와 아래 메시지를 보여준다.
struct DWTextField: View {
    let title: String
    let placeholder: String
    @Binding var text: String
    var systemImage: String?
    var errorMessage: String?
    var helperText: String?
    var keyboard: DWKeyboard = .default
    var isSecure = false

    @FocusState private var isFocused: Bool

    enum DWKeyboard {
        case `default`, number, email
    }

    var body: some View {
        VStack(alignment: .leading, spacing: DWSpacing.xs + 2) {
            if !title.isEmpty {
                Text(title).dwFont(.footnote, color: DWColor.textSecondary)
            }
            HStack(spacing: DWSpacing.sm) {
                if let systemImage {
                    Image(systemName: systemImage)
                        .foregroundStyle(isFocused ? DWColor.primary : DWColor.textTertiary)
                        .accessibilityHidden(true)
                }
                field
                    .dwFont(.body)
                    .focused($isFocused)
                if !text.isEmpty && isFocused {
                    Button {
                        text = ""
                    } label: {
                        Image(systemName: "xmark.circle.fill").foregroundStyle(DWColor.textTertiary)
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel("입력 지우기")
                }
            }
            .padding(.horizontal, DWSpacing.lg)
            .frame(minHeight: 52)
            .background(DWColor.subtle, in: RoundedRectangle.dw(DWRadius.md))
            .overlay(
                RoundedRectangle.dw(DWRadius.md)
                    .strokeBorder(borderColor, lineWidth: isFocused || errorMessage != nil ? 1.5 : 0)
            )
            .animation(DWMotion.quick, value: isFocused)

            if let errorMessage {
                Label(errorMessage, systemImage: "exclamationmark.circle.fill")
                    .labelStyle(.titleAndIcon)
                    .dwFont(.footnote, color: DWColor.danger)
            } else if let helperText {
                Text(helperText).dwFont(.footnote, color: DWColor.textTertiary)
            }
        }
        .accessibilityElement(children: .contain)
    }

    @ViewBuilder
    private var field: some View {
        let prompt = Text(placeholder).foregroundStyle(DWColor.textTertiary)
        if isSecure {
            SecureField(title, text: $text, prompt: prompt)
        } else {
            TextField(title, text: $text, prompt: prompt)
                .keyboardType(keyboardType)
                .textInputAutocapitalization(keyboard == .email ? .never : .sentences)
                .autocorrectionDisabled(keyboard == .email)
        }
    }

    private var keyboardType: UIKeyboardType {
        switch keyboard {
        case .default: return .default
        case .number: return .numberPad
        case .email: return .emailAddress
        }
    }

    private var borderColor: Color {
        if errorMessage != nil { return DWColor.danger }
        return isFocused ? DWColor.primary : .clear
    }
}

#Preview("입력 필드") {
    struct Demo: View {
        @State private var name = ""
        @State private var email = "family@"
        @State private var amount = "32000"
        var body: some View {
            VStack(spacing: DWSpacing.lg) {
                DWTextField(title: "그룹 이름", placeholder: "예: 우리집", text: $name, helperText: "최대 30자")
                DWTextField(title: "이메일", placeholder: "name@example.com", text: $email, systemImage: "envelope",
                            errorMessage: "이메일 형식을 확인해 주세요", keyboard: .email)
                DWTextField(title: "금액", placeholder: "0", text: $amount, systemImage: "wonsign", keyboard: .number)
            }
            .padding()
            .background(DWColor.canvas)
        }
    }
    return Demo()
}
