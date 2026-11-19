import SwiftUI

/// 복주머니 심볼 (앱 아이콘과 같은 형태의 벡터 버전).
/// 도깨비를 직접 그리지 않고, 풍요를 뜻하는 복주머니와 방망이 돌기를 단순화한 "행운 점"으로 표현한다.
struct LuckyPouchShape: Shape {
    func path(in rect: CGRect) -> Path {
        let w = rect.width, h = rect.height
        func p(_ x: CGFloat, _ y: CGFloat) -> CGPoint { CGPoint(x: rect.minX + x * w, y: rect.minY + y * h) }
        var path = Path()
        // 몸통: 목에서 아래로 넓어지는 둥근 주머니
        path.move(to: p(0.37, 0.42))
        path.addCurve(to: p(0.10, 0.74), control1: p(0.30, 0.52), control2: p(0.10, 0.60))
        path.addCurve(to: p(0.50, 0.98), control1: p(0.10, 0.90), control2: p(0.30, 0.98))
        path.addCurve(to: p(0.90, 0.74), control1: p(0.70, 0.98), control2: p(0.90, 0.90))
        path.addCurve(to: p(0.63, 0.42), control1: p(0.90, 0.60), control2: p(0.70, 0.52))
        path.closeSubpath()
        // 목 주름: 세 갈래 꽃잎
        for center: CGFloat in [0.33, 0.50, 0.67] {
            path.addEllipse(in: CGRect(x: rect.minX + (center - 0.105) * w, y: rect.minY + 0.02 * h,
                                       width: 0.21 * w, height: 0.36 * h))
        }
        return path
    }
}

/// 3×3 행운 점 패턴 (DESIGN_SYSTEM.md §1.1)
struct LuckyDotPattern: View {
    var dotSize: CGFloat = 4
    var spacing: CGFloat = 6

    var body: some View {
        Grid(horizontalSpacing: spacing, verticalSpacing: spacing) {
            ForEach(0..<3, id: \.self) { _ in
                GridRow {
                    ForEach(0..<3, id: \.self) { _ in
                        Circle().frame(width: dotSize, height: dotSize)
                    }
                }
            }
        }
        .accessibilityHidden(true)
    }
}

/// 브랜드 심볼: 딥그린 둥근 사각형 + 금빛 복주머니
struct DWBrandMark: View {
    var size: CGFloat = 40

    var body: some View {
        ZStack {
            RoundedRectangle.dw(size * 0.28)
                .fill(DWColor.primary)
            LuckyPouchShape()
                .fill(LinearGradient(colors: [DWColor.gold.opacity(0.85), DWColor.gold],
                                     startPoint: .top, endPoint: .bottom))
                .frame(width: size * 0.56, height: size * 0.6)
                .offset(y: size * 0.02)
            // 매듭
            Capsule()
                .fill(DWColor.primary)
                .frame(width: size * 0.3, height: size * 0.05)
                .offset(y: -size * 0.055)
        }
        .frame(width: size, height: size)
        .accessibilityHidden(true)
    }
}

/// 로고 + 서비스명 (+ 영문명)
struct DWLogo: View {
    var markSize: CGFloat = 36
    var showsEnglishName = true

    var body: some View {
        HStack(spacing: DWSpacing.sm + 2) {
            DWBrandMark(size: markSize)
            VStack(alignment: .leading, spacing: 0) {
                Text(AppDefaults.serviceName)
                    .font(.system(.title3, weight: .bold))
                    .kerning(-0.4)
                    .foregroundStyle(DWColor.textPrimary)
                if showsEnglishName {
                    Text(AppDefaults.serviceNameEnglish)
                        .font(.system(.caption2, weight: .semibold))
                        .kerning(1.2)
                        .foregroundStyle(DWColor.brown)
                }
            }
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(AppDefaults.serviceName)
    }
}

#Preview("브랜드") {
    VStack(spacing: DWSpacing.xl) {
        DWLogo()
        DWBrandMark(size: 120)
        Text(AppDefaults.slogan).dwFont(.subheadline, color: DWColor.textSecondary)
    }
    .padding()
    .frame(maxWidth: .infinity, maxHeight: .infinity)
    .background(DWColor.canvas)
}
