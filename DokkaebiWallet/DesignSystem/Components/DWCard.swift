import SwiftUI

/// 흰 카드 컨테이너 (DESIGN_SYSTEM.md §5). 헤더(제목 + 더보기)는 선택 사항이다.
struct DWCard<Content: View>: View {
    var title: String?
    var subtitle: String?
    var actionTitle: String?
    var action: (() -> Void)?
    var padding: CGFloat = DWSpacing.cardPadding
    @ViewBuilder let content: Content

    var body: some View {
        VStack(alignment: .leading, spacing: DWSpacing.lg) {
            if title != nil || actionTitle != nil {
                DWSectionHeader(title: title ?? "", subtitle: subtitle, actionTitle: actionTitle, action: action)
            }
            content
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(padding)
        .dwCardBackground()
    }
}

extension View {
    /// 카드 배경 스타일: 표면색, 큰 반경, 0.5pt 테두리, 카드 그림자
    func dwCardBackground(radius: CGFloat = DWRadius.lg) -> some View {
        background(DWColor.surface, in: RoundedRectangle.dw(radius))
            .overlay(RoundedRectangle.dw(radius).strokeBorder(DWColor.border, lineWidth: 0.5))
            .dwShadow(.card)
    }
}

/// 섹션 제목과 "더보기" 동작
struct DWSectionHeader: View {
    let title: String
    var subtitle: String?
    var actionTitle: String?
    var action: (() -> Void)?

    var body: some View {
        HStack(alignment: .firstTextBaseline) {
            VStack(alignment: .leading, spacing: DWSpacing.xxs) {
                Text(title).dwFont(.title3)
                    .accessibilityAddTraits(.isHeader)
                if let subtitle {
                    Text(subtitle).dwFont(.footnote, color: DWColor.textSecondary)
                }
            }
            Spacer(minLength: DWSpacing.sm)
            if let actionTitle, let action {
                Button(action: action) {
                    HStack(spacing: 2) {
                        Text(actionTitle)
                        Image(systemName: "chevron.right").font(.caption.weight(.semibold))
                    }
                    .dwFont(.footnote, color: DWColor.primary)
                    .frame(minHeight: DWSpacing.minTouchTarget)
                }
                .buttonStyle(.plain)
            }
        }
    }
}

#Preview("카드") {
    ScrollView {
        VStack(spacing: DWSpacing.cardGap) {
            DWCard(title: "최근 거래", actionTitle: "더보기", action: {}) {
                Text("카드 내용").dwFont(.body)
            }
            DWCard {
                Text("헤더 없는 카드").dwFont(.body)
            }
        }
        .padding(DWSpacing.screenHorizontal)
    }
    .background(DWColor.canvas)
}
