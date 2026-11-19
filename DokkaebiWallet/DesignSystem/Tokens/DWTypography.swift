import SwiftUI

/// 타이포그래피 토큰 (DESIGN_SYSTEM.md §3).
/// 시스템 서체를 쓰므로 한글은 Apple SD Gothic Neo로 자동 대체되고, 모든 크기가 Dynamic Type을 따른다.
enum DWTypography: CaseIterable {
    case display, title1, title2, title3, headline, body, callout, subheadline, footnote, caption
    case amountLarge, amountRow

    var font: Font {
        switch self {
        case .display: return .system(.largeTitle, design: .rounded, weight: .bold).monospacedDigit()
        case .title1: return .system(.title, weight: .bold)
        case .title2: return .system(.title2, weight: .semibold)
        case .title3: return .system(.title3, weight: .semibold)
        case .headline: return .system(.headline, weight: .semibold)
        case .body: return .system(.body)
        case .callout: return .system(.callout)
        case .subheadline: return .system(.subheadline)
        case .footnote: return .system(.footnote)
        case .caption: return .system(.caption, weight: .medium)
        case .amountLarge: return .system(.title, design: .rounded, weight: .bold).monospacedDigit()
        case .amountRow: return .system(.body, weight: .semibold).monospacedDigit()
        }
    }

    /// 한글 본문 가독성을 위한 추가 행간
    var lineSpacing: CGFloat {
        switch self {
        case .body, .callout: return 2
        default: return 0
        }
    }

    var sampleName: String {
        switch self {
        case .display: return "Display"
        case .title1: return "Title 1"
        case .title2: return "Title 2"
        case .title3: return "Title 3"
        case .headline: return "Headline"
        case .body: return "Body"
        case .callout: return "Callout"
        case .subheadline: return "Subheadline"
        case .footnote: return "Footnote"
        case .caption: return "Caption"
        case .amountLarge: return "Amount Large"
        case .amountRow: return "Amount Row"
        }
    }
}

extension View {
    /// 타이포그래피 토큰 적용. 색을 지정하지 않으면 기본 텍스트색을 쓴다.
    func dwFont(_ style: DWTypography, color: Color? = nil) -> some View {
        font(style.font)
            .lineSpacing(style.lineSpacing)
            .foregroundStyle(color ?? DWColor.textPrimary)
    }
}
