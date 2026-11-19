import Foundation

/// 카테고리·구성원·지갑 카드에 쓰는 16색 팔레트 토큰 (DESIGN_SYSTEM.md §2.3).
/// 모델은 UI 프레임워크에 의존하지 않도록 토큰 이름만 가지며, 실제 색은 Asset Catalog에서 불러온다.
public enum PaletteColor: String, Codable, Sendable, CaseIterable {
    case pine = "palettePine"           // 솔잎
    case moss = "paletteMoss"           // 이끼
    case ochre = "paletteOchre"         // 황토
    case maple = "paletteMaple"         // 단풍
    case pomegranate = "palettePomegranate" // 석류
    case plum = "palettePlum"           // 자두
    case indigo = "paletteIndigo"       // 쪽빛
    case sky = "paletteSky"             // 하늘
    case celadon = "paletteCeladon"     // 청자
    case gold = "paletteGold"           // 금
    case chestnut = "paletteChestnut"   // 밤
    case ink = "paletteInk"             // 먹
    case apricot = "paletteApricot"     // 살구
    case azalea = "paletteAzalea"       // 진달래
    case mugwort = "paletteMugwort"     // 쑥
    case sand = "paletteSand"           // 모래

    /// Asset Catalog 색상 이름
    public var assetName: String { rawValue }
}
