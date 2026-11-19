import SwiftUI

/// 하단 토스트 (DESIGN_SYSTEM.md §5). 실행 취소 등 동작 하나를 붙일 수 있다.
struct DWToast: Identifiable, Equatable {
    let id = UUID()
    let message: String
    var systemImage: String?
    var actionTitle: String?
    var action: (() -> Void)?
    var duration: Duration = .seconds(3)

    static func == (lhs: DWToast, rhs: DWToast) -> Bool { lhs.id == rhs.id }
}

private struct DWToastModifier: ViewModifier {
    @Binding var toast: DWToast?

    func body(content: Content) -> some View {
        content.overlay(alignment: .bottom) {
            if let toast {
                HStack(spacing: DWSpacing.md) {
                    if let systemImage = toast.systemImage {
                        Image(systemName: systemImage).accessibilityHidden(true)
                    }
                    Text(toast.message).frame(maxWidth: .infinity, alignment: .leading)
                    if let title = toast.actionTitle, let action = toast.action {
                        Button(title) {
                            action()
                            self.toast = nil
                        }
                        .fontWeight(.semibold)
                        .foregroundStyle(DWColor.gold)
                    }
                }
                .font(DWTypography.subheadline.font)
                .foregroundStyle(DWColor.canvas)
                .padding(.horizontal, DWSpacing.lg)
                .padding(.vertical, DWSpacing.md)
                .background(DWColor.textPrimary, in: RoundedRectangle.dw(DWRadius.md))
                .dwShadow(.floating)
                .padding(.horizontal, DWSpacing.screenHorizontal)
                .padding(.bottom, DWSpacing.lg)
                .transition(.move(edge: .bottom).combined(with: .opacity))
                .task(id: toast.id) {
                    try? await Task.sleep(for: toast.duration)
                    withAnimation(DWMotion.standard) { self.toast = nil }
                }
                .accessibilityElement(children: .combine)
            }
        }
        .animation(DWMotion.standard, value: toast)
    }
}

extension View {
    func dwToast(_ toast: Binding<DWToast?>) -> some View {
        modifier(DWToastModifier(toast: toast))
    }
}
