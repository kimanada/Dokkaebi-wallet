#if canImport(UIKit)
import Testing
import UIKit
@testable import DokkaebiWallet

@MainActor
@Suite("디자인 시스템")
struct DesignSystemTests {
    @Test("모든 색상 토큰이 Asset Catalog에 있고 라이트·다크 값이 다르다", arguments: DWColor.allAssetNames)
    func colorAssets(name: String) throws {
        let color = try #require(UIColor(named: name, in: .main, compatibleWith: nil), "\(name) 색상이 없습니다")
        let light = color.resolvedColor(with: UITraitCollection(userInterfaceStyle: .light))
        let dark = color.resolvedColor(with: UITraitCollection(userInterfaceStyle: .dark))
        // 흰 표면(bgSurface)처럼 의도적으로 같은 색은 없으므로 모두 달라야 한다.
        #expect(light != dark, "\(name)의 라이트·다크 값이 같습니다")
    }

    /// 글자색/배경색 조합 (DESIGN_SYSTEM.md §2.4). 골드는 장식 전용이라 제외한다.
    static let contrastPairs: [(text: String, background: String)] = [
        ("textPrimary", "bgCanvas"), ("textPrimary", "bgSurface"), ("textPrimary", "bgSubtle"),
        ("textSecondary", "bgCanvas"), ("textSecondary", "bgSurface"), ("textSecondary", "bgSubtle"),
        ("textTertiary", "bgCanvas"), ("textTertiary", "bgSurface"), ("textTertiary", "bgSubtle"),
        ("brandPrimary", "bgCanvas"), ("brandPrimary", "bgSurface"), ("brandPrimary", "brandPrimarySoft"),
        ("brandOnPrimary", "brandPrimary"),
        ("semanticIncome", "bgSurface"), ("semanticIncome", "bgSubtle"),
        ("semanticDanger", "bgSurface"), ("semanticWarning", "bgSurface"), ("semanticWarning", "bgCanvas"),
        ("semanticInfo", "bgSurface"), ("accentBrown", "accentGoldSoft"), ("accentBrown", "bgCanvas"),
        ("bgCanvas", "semanticDanger"), ("bgCanvas", "textPrimary")
    ]

    @Test("글자색 대비 4.5:1 이상 (라이트·다크)", arguments: DesignSystemTests.contrastPairs.map { "\($0.text)/\($0.background)" })
    func contrast(pair: String) throws {
        let names = pair.split(separator: "/").map(String.init)
        let text = try #require(UIColor(named: names[0], in: .main, compatibleWith: nil))
        let background = try #require(UIColor(named: names[1], in: .main, compatibleWith: nil))
        for style in [UIUserInterfaceStyle.light, .dark] {
            let traits = UITraitCollection(userInterfaceStyle: style)
            let ratio = Self.contrastRatio(text.resolvedColor(with: traits), background.resolvedColor(with: traits))
            #expect(ratio >= 4.5, "\(pair) \(style == .light ? "라이트" : "다크") 대비 \(ratio)")
        }
    }

    /// WCAG 2.x 상대 휘도 기반 대비
    static func contrastRatio(_ a: UIColor, _ b: UIColor) -> Double {
        func luminance(_ color: UIColor) -> Double {
            var r: CGFloat = 0, g: CGFloat = 0, b: CGFloat = 0, alpha: CGFloat = 0
            color.getRed(&r, green: &g, blue: &b, alpha: &alpha)
            func channel(_ v: CGFloat) -> Double {
                let v = Double(v)
                return v <= 0.03928 ? v / 12.92 : pow((v + 0.055) / 1.055, 2.4)
            }
            return 0.2126 * channel(r) + 0.7152 * channel(g) + 0.0722 * channel(b)
        }
        let (l1, l2) = (luminance(a), luminance(b))
        return (max(l1, l2) + 0.05) / (min(l1, l2) + 0.05)
    }

    @Test("지원하는 바코드 유형은 이미지를 만든다", arguments: [BarcodeType.qr, .code128, .pdf417, .aztec])
    func barcode(type: BarcodeType) throws {
        let image = try BarcodeGenerator.image(for: "DOKKAEBI-1234", type: type)
        #expect(image.size.width > 0)
    }

    @Test("미지원 유형과 잘못된 값")
    func barcodeFailures() {
        #expect(throws: BarcodeGenerator.Failure.unsupportedType(.ean13)) {
            try BarcodeGenerator.image(for: "8801234567890", type: .ean13)
        }
        #expect(throws: BarcodeGenerator.Failure.invalidValue) {
            try BarcodeGenerator.image(for: "한글", type: .code128)
        }
    }
}
#endif
