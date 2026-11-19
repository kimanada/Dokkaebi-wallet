import SwiftUI

/// 버튼 종류와 크기 (DESIGN_SYSTEM.md §5)
enum DWButtonKind {
    /// 딥그린 채움
    case primary
    /// 연한 그린 배경, 딥그린 글씨
    case secondary
    /// 텍스트만
    case tertiary
    /// 삭제 등 파괴적 동작
    case destructive
}

enum DWButtonSize {
    case large, medium, small

    var height: CGFloat {
        switch self {
        case .large: return 52
        case .medium: return 44
        case .small: return 32
        }
    }

    var font: Font {
        switch self {
        case .large, .medium: return DWTypography.headline.font
        case .small: return DWTypography.subheadline.font.weight(.semibold)
        }
    }

    var horizontalPadding: CGFloat {
        switch self {
        case .large: return DWSpacing.xl
        case .medium: return DWSpacing.lg
        case .small: return DWSpacing.md
        }
    }
}

struct DWButtonStyle: ButtonStyle {
    var kind: DWButtonKind = .primary
    var size: DWButtonSize = .large
    var fillsWidth = true

    @Environment(\.isEnabled) private var isEnabled

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(size.font)
            .lineLimit(1)
            .minimumScaleFactor(0.85)
            .foregroundStyle(foreground)
            .padding(.horizontal, size.horizontalPadding)
            .frame(maxWidth: fillsWidth ? .infinity : nil, minHeight: size.height)
            .background(background(pressed: configuration.isPressed), in: RoundedRectangle.dw(DWRadius.md))
            .contentShape(RoundedRectangle.dw(DWRadius.md))
            .opacity(isEnabled ? 1 : 0.45)
            .scaleEffect(configuration.isPressed ? 0.97 : 1)
            .animation(DWMotion.quick, value: configuration.isPressed)
    }

    private var foreground: Color {
        switch kind {
        case .primary: return DWColor.onPrimary
        case .secondary, .tertiary: return DWColor.primary
        case .destructive: return DWColor.canvas
        }
    }

    private func background(pressed: Bool) -> Color {
        switch kind {
        case .primary: return pressed ? DWColor.primaryPressed : DWColor.primary
        case .secondary: return DWColor.primarySoft.opacity(pressed ? 0.7 : 1)
        case .tertiary: return pressed ? DWColor.subtle : .clear
        case .destructive: return DWColor.danger.opacity(pressed ? 0.85 : 1)
        }
    }
}

/// 공통 버튼. 로딩 중에는 진행 표시를 보여주고 다시 누를 수 없다.
struct DWButton: View {
    let title: String
    var systemImage: String?
    var kind: DWButtonKind = .primary
    var size: DWButtonSize = .large
    var fillsWidth = true
    var isLoading = false
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: DWSpacing.sm) {
                if isLoading {
                    ProgressView()
                        .tint(kind == .primary || kind == .destructive ? DWColor.onPrimary : DWColor.primary)
                } else if let systemImage {
                    Image(systemName: systemImage)
                }
                Text(title)
            }
        }
        .buttonStyle(DWButtonStyle(kind: kind, size: size, fillsWidth: fillsWidth))
        .disabled(isLoading)
        .accessibilityLabel(isLoading ? "\(title), 처리 중" : title)
    }
}

/// 원형 아이콘 버튼 (내비게이션 바, 카드 헤더용). 터치 영역 44pt를 보장한다.
struct DWIconButton: View {
    let systemImage: String
    let accessibilityLabel: String
    var badgeCount = 0
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Image(systemName: systemImage)
                .font(.system(size: 17, weight: .medium))
                .foregroundStyle(DWColor.textPrimary)
                .frame(width: 40, height: 40)
                .background(DWColor.surface, in: Circle())
                .overlay(Circle().strokeBorder(DWColor.border, lineWidth: 0.5))
                .overlay(alignment: .topTrailing) {
                    if badgeCount > 0 { DWBadge(count: badgeCount).offset(x: 6, y: -4) }
                }
                .frame(minWidth: DWSpacing.minTouchTarget, minHeight: DWSpacing.minTouchTarget)
        }
        .buttonStyle(.plain)
        .accessibilityLabel(badgeCount > 0 ? "\(accessibilityLabel), 읽지 않은 항목 \(badgeCount)개" : accessibilityLabel)
    }
}

#Preview("버튼") {
    VStack(spacing: DWSpacing.md) {
        DWButton(title: "저장하기", kind: .primary) {}
        DWButton(title: "지난달 예산 불러오기", systemImage: "arrow.down.doc", kind: .secondary) {}
        DWButton(title: "나중에 할게요", kind: .tertiary) {}
        DWButton(title: "삭제", kind: .destructive, size: .medium) {}
        DWButton(title: "저장 중", isLoading: true) {}
        DWButton(title: "비활성", kind: .primary) {}.disabled(true)
        HStack {
            DWButton(title: "작게", kind: .secondary, size: .small, fillsWidth: false) {}
            DWIconButton(systemImage: "bell", accessibilityLabel: "알림", badgeCount: 3) {}
        }
    }
    .padding()
    .background(DWColor.canvas)
}
