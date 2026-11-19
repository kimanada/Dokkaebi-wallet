import Foundation
#if canImport(UIKit) && canImport(CoreImage)
@preconcurrency import CoreImage
import CoreImage.CIFilterBuiltins
import UIKit

/// 바코드·QR 이미지 생성기 (FR-WAL-02).
/// Core Image가 지원하는 QR, Code128, PDF417, Aztec만 생성한다.
/// EAN-13/8, UPC-A, Code39, ITF 인코더는 지갑 단계(DEVELOPMENT_ROADMAP.md Phase 4)에서 직접 구현한다.
enum BarcodeGenerator {
    enum Failure: Error, Equatable {
        case unsupportedType(BarcodeType)
        case invalidValue
    }

    /// CIContext는 스레드 안전하며 생성 비용이 커서 재사용한다 (Apple 문서 기준).
    nonisolated(unsafe) private static let context = CIContext()

    static func isSupported(_ type: BarcodeType) -> Bool {
        switch type {
        case .qr, .code128, .pdf417, .aztec: return true
        default: return false
        }
    }

    /// 확대 배율을 적용한 이미지. 화면에서는 `.interpolation(.none)`으로 그려 선명도를 유지한다.
    static func image(for value: String, type: BarcodeType, scale: CGFloat = 8) throws -> UIImage {
        let output: CIImage?
        switch type {
        case .qr:
            let filter = CIFilter.qrCodeGenerator()
            filter.message = Data(value.utf8)
            filter.correctionLevel = "M"
            output = filter.outputImage
        case .code128:
            guard let data = value.data(using: .ascii) else { throw Failure.invalidValue }
            let filter = CIFilter.code128BarcodeGenerator()
            filter.message = data
            filter.quietSpace = 10
            output = filter.outputImage
        case .pdf417:
            let filter = CIFilter.pdf417BarcodeGenerator()
            filter.message = Data(value.utf8)
            output = filter.outputImage
        case .aztec:
            let filter = CIFilter.aztecCodeGenerator()
            filter.message = Data(value.utf8)
            output = filter.outputImage
        default:
            throw Failure.unsupportedType(type)
        }
        guard let image = output?.transformed(by: CGAffineTransform(scaleX: scale, y: scale)),
              let cgImage = context.createCGImage(image, from: image.extent) else {
            throw Failure.invalidValue
        }
        return UIImage(cgImage: cgImage)
    }
}
#endif
