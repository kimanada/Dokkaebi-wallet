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
