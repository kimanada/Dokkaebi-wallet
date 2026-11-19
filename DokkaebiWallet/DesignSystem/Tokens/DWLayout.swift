import SwiftUI

/// 간격 토큰 — 4pt 그리드 (DESIGN_SYSTEM.md §4.1)
enum DWSpacing {
    static let xxs: CGFloat = 2
    static let xs: CGFloat = 4
    static let sm: CGFloat = 8
    static let md: CGFloat = 12
    static let lg: CGFloat = 16
    static let xl: CGFloat = 20
    static let xxl: CGFloat = 24
    static let xxxl: CGFloat = 32

    /// 화면 좌우 여백
    static let screenHorizontal: CGFloat = 20
    /// 카드 안쪽 여백
    static let cardPadding: CGFloat = 20
    /// 카드 사이 간격
    static let cardGap: CGFloat = 16
    /// 최소 터치 영역
    static let minTouchTarget: CGFloat = 44
}

/// 모서리 반경 토큰 (DESIGN_SYSTEM.md §4.2). 항상 `.continuous` 스타일로 쓴다.
enum DWRadius {
    static let sm: CGFloat = 8
    static let md: CGFloat = 12
    static let lg: CGFloat = 20
    static let xl: CGFloat = 28
}

extension RoundedRectangle {
    /// 디자인 시스템 반경을 쓰는 연속 곡률 사각형
    static func dw(_ radius: CGFloat) -> RoundedRectangle {
        RoundedRectangle(cornerRadius: radius, style: .continuous)
    }
}

/// 그림자 토큰 (DESIGN_SYSTEM.md §4.3). 다크 모드에서는 그림자 대신 표면 명도 차이로 깊이를 표현한다.
enum DWShadow {
    case card, floating

    var opacity: Double {
        switch self {
        case .card: return 0.04
        case .floating: return 0.10
        }
    }

    var radius: CGFloat {
        switch self {
        case .card: return 12
        case .floating: return 24
        }
    }

    var y: CGFloat {
        switch self {
        case .card: return 2
        case .floating: return 8
        }
    }
}

private struct DWShadowModifier: ViewModifier {
    let shadow: DWShadow
    @Environment(\.colorScheme) private var colorScheme

    func body(content: Content) -> some View {
        switch (colorScheme, shadow) {
        case (.dark, .card):
            content
        case (.dark, .floating):
            content.shadow(color: DWColor.shadow.opacity(0.4), radius: shadow.radius, y: shadow.y)
        default:
            content.shadow(color: DWColor.shadow.opacity(shadow.opacity), radius: shadow.radius, y: shadow.y)
        }
    }
}

extension View {
    func dwShadow(_ shadow: DWShadow) -> some View {
        modifier(DWShadowModifier(shadow: shadow))
    }
}

/// 모션 토큰 (DESIGN_SYSTEM.md §7)
enum DWMotion {
    static let quick: Animation = .snappy(duration: 0.2)
    static let standard: Animation = .smooth(duration: 0.3)
    static let emphasis: Animation = .bouncy(duration: 0.45, extraBounce: 0.1)
}
