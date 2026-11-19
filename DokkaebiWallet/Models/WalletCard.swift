import Foundation

public enum WalletScope: String, Codable, Sendable {
    case personal, family

    public var displayName: String {
        switch self {
        case .personal: return "개인 지갑"
        case .family: return "가족 공유"
        }
    }
}

public enum BarcodeType: String, Codable, Sendable, CaseIterable {
    case qr, code128, ean13, ean8, upca, code39, itf, pdf417, aztec, dataMatrix = "data_matrix", imageOnly = "image_only"

    public var displayName: String {
        switch self {
        case .qr: return "QR 코드"
        case .code128: return "Code 128"
        case .ean13: return "EAN-13"
        case .ean8: return "EAN-8"
        case .upca: return "UPC-A"
        case .code39: return "Code 39"
        case .itf: return "ITF"
        case .pdf417: return "PDF417"
        case .aztec: return "Aztec"
        case .dataMatrix: return "Data Matrix"
        case .imageOnly: return "이미지"
        }
    }

    /// 1차원(가로로 긴) 바코드인지. 전체 화면에서 가로 표시를 안내한다.
    public var isLinear: Bool {
        switch self {
        case .code128, .ean13, .ean8, .upca, .code39, .itf: return true
        default: return false
        }
    }
}

public struct WalletCard: Identifiable, Hashable, Codable, Sendable {
    public let id: UUID
    public var scope: WalletScope
    public var brandName: String
    public var cardName: String?
    public var cardNumber: String?
    public var barcodeValue: String?
    public var barcodeType: BarcodeType
    public var memo: String?
    public var color: PaletteColor
    public var isFavorite: Bool

    public init(id: UUID = UUID(), scope: WalletScope, brandName: String, cardName: String? = nil,
                cardNumber: String? = nil, barcodeValue: String? = nil, barcodeType: BarcodeType = .qr,
                memo: String? = nil, color: PaletteColor = .pine, isFavorite: Bool = false) {
        self.id = id
        self.scope = scope
        self.brandName = brandName
        self.cardName = cardName
        self.cardNumber = cardNumber
        self.barcodeValue = barcodeValue
        self.barcodeType = barcodeType
        self.memo = memo
        self.color = color
        self.isFavorite = isFavorite
    }

    /// 화면 표시용 번호 (4자리마다 띄어쓰기)
    public var formattedNumber: String? {
        guard let number = cardNumber ?? barcodeValue, !number.isEmpty else { return nil }
        let chars = Array(number.replacingOccurrences(of: " ", with: ""))
        return stride(from: 0, to: chars.count, by: 4)
            .map { String(chars[$0..<Swift.min($0 + 4, chars.count)]) }
            .joined(separator: " ")
    }
}
