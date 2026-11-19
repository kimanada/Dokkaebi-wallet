#!/usr/bin/env python3
"""도깨비 지갑 Asset Catalog 생성 스크립트.

DESIGN_SYSTEM.md의 색상 토큰(라이트/다크)을 Color Set으로 만들고, 앱 아이콘 PNG를 그린다.
색상을 바꿀 때는 이 파일의 COLORS를 수정한 뒤 다시 실행한다:
    python3 scripts/generate_assets.py
"""
import json
import math
import os

ROOT = os.path.join(os.path.dirname(__file__), "..", "DokkaebiWallet", "Resources", "Assets.xcassets")

# 이름: (라이트, 다크)
COLORS = {
    # 배경
    "bgCanvas": ("#FAF7F0", "#121412"),
    "bgSurface": ("#FFFFFF", "#1C1F1C"),
    "bgSurfaceElevated": ("#FFFFFF", "#242824"),
    "bgSubtle": ("#F2EDE3", "#2A2E2A"),
    # 브랜드
    "brandPrimary": ("#1F4D3A", "#6FB08F"),
    "brandPrimaryPressed": ("#163A2B", "#5A9A7A"),
    "brandOnPrimary": ("#FFFFFF", "#0E1F17"),
    "brandPrimarySoft": ("#E3EDE7", "#1E3329"),
    # 보조
    "accentGold": ("#B8913A", "#D4B266"),
    "accentGoldSoft": ("#F4EBD6", "#3A3222"),
    "accentBeige": ("#E8DCC8", "#3B352B"),
    "accentBrown": ("#7A5C43", "#C4A386"),
    # 텍스트
    "textPrimary": ("#1E1E1C", "#F2F0EA"),
    "textSecondary": ("#5F5A52", "#B5B0A6"),
    "textTertiary": ("#8F897E", "#7F7A71"),
    # 테두리
    "borderDefault": ("#E6E0D4", "#33372F"),
    "borderStrong": ("#CFC6B5", "#4A4F46"),
    # 의미
    "semanticIncome": ("#2E7D5B", "#7CC4A0"),
    "semanticSuccess": ("#2E7D5B", "#7CC4A0"),
    "semanticWarning": ("#95600F", "#E3B45C"),
    "semanticDanger": ("#B3412E", "#EE8A76"),
    "semanticInfo": ("#3A6A8C", "#8DB7D6"),
    # 그림자 색 (투명도는 코드에서 적용)
    "shadowColor": ("#1E1E1C", "#000000"),
    # 카테고리·구성원 팔레트 16색
    "palettePine": ("#3F7A5E", "#74B394"),
    "paletteMoss": ("#7C8B4A", "#AEBE7A"),
    "paletteOchre": ("#B8793A", "#DDA66C"),
    "paletteMaple": ("#B5523B", "#E08A73"),
    "palettePomegranate": ("#9C3D54", "#D27A90"),
    "palettePlum": ("#6E4A7E", "#A78BB7"),
    "paletteIndigo": ("#3D5A8A", "#86A2CF"),
    "paletteSky": ("#4D8AA8", "#8CC0D8"),
    "paletteCeladon": ("#4F9A8F", "#8ACBC1"),
    "paletteGold": ("#B8913A", "#D4B266"),
    "paletteChestnut": ("#7A5C43", "#C4A386"),
    "paletteInk": ("#4A4A48", "#A8A8A4"),
    "paletteApricot": ("#D08A5E", "#EDB38E"),
    "paletteAzalea": ("#C0678E", "#E5A0BE"),
    "paletteMugwort": ("#6F9A6A", "#A6CDA1"),
    "paletteSand": ("#A89A7C", "#CFC3A8"),
}

INFO = {"author": "xcode", "version": 1}


def components(hex_value):
    h = hex_value.lstrip("#")
    r, g, b = (int(h[i:i + 2], 16) for i in (0, 2, 4))
    return {"alpha": "1.000", "blue": f"0x{b:02X}", "green": f"0x{g:02X}", "red": f"0x{r:02X}"}


def color_entry(hex_value, dark=False):
    entry = {"color": {"color-space": "srgb", "components": components(hex_value)}, "idiom": "universal"}
    if dark:
        entry["appearances"] = [{"appearance": "luminosity", "value": "dark"}]
    return entry


def write_json(path, data):
    os.makedirs(os.path.dirname(path), exist_ok=True)
    with open(path, "w", encoding="utf-8") as f:
        json.dump(data, f, indent=2, ensure_ascii=False)
        f.write("\n")


def write_colors():
    write_json(os.path.join(ROOT, "Contents.json"), {"info": INFO})
    for name, (light, dark) in COLORS.items():
        write_json(os.path.join(ROOT, f"{name}.colorset", "Contents.json"),
                   {"colors": [color_entry(light), color_entry(dark, dark=True)], "info": INFO})
    # AccentColor = 브랜드 딥그린 (시스템 컨트롤 기본 강조색)
    light, dark = COLORS["brandPrimary"]
    write_json(os.path.join(ROOT, "AccentColor.colorset", "Contents.json"),
               {"colors": [color_entry(light), color_entry(dark, dark=True)], "info": INFO})
    # 실행 화면 배경
    light, dark = COLORS["bgCanvas"]
    write_json(os.path.join(ROOT, "LaunchBackground.colorset", "Contents.json"),
               {"colors": [color_entry(light), color_entry(dark, dark=True)], "info": INFO})


# ---------------------------------------------------------------- 앱 아이콘
# 콘셉트: 딥그린 바탕 위의 금빛 복주머니. 주머니 몸통의 매듭 아래 "행운 점" 3×3 패턴은
# 도깨비 방망이의 돌기를 기하학적으로 단순화한 브랜드 요소다 (DESIGN_SYSTEM.md §1.1).
def draw_icon(size, variant):
    from PIL import Image, ImageDraw, ImageFilter

    s = size
    scale = 4  # 안티에일리어싱용 슈퍼샘플링
    S = s * scale
    if variant == "dark":
        top, bottom = (16, 30, 23), (8, 16, 12)
        gold_light, gold_dark = (222, 190, 112), (176, 138, 58)
    elif variant == "tinted":
        top, bottom = (40, 40, 40), (12, 12, 12)
        gold_light, gold_dark = (245, 245, 245), (190, 190, 190)
    else:
        top, bottom = (36, 92, 69), (20, 56, 41)
        gold_light, gold_dark = (232, 202, 128), (184, 145, 58)

    img = Image.new("RGB", (S, S))
    px = ImageDraw.Draw(img)
    for y in range(S):  # 세로 그라데이션 배경
        t = y / (S - 1)
        px.line([(0, y), (S, y)], fill=tuple(int(top[i] + (bottom[i] - top[i]) * t) for i in range(3)))

    # 금빛 그라데이션 레이어
    gold = Image.new("RGB", (S, S))
    gd = ImageDraw.Draw(gold)
    for y in range(S):
        t = min(max((y - S * 0.2) / (S * 0.65), 0), 1)
        gd.line([(0, y), (S, y)], fill=tuple(int(gold_light[i] + (gold_dark[i] - gold_light[i]) * t) for i in range(3)))

    mask = Image.new("L", (S, S), 0)
    m = ImageDraw.Draw(mask)
    cx = S / 2

    def smoothstep(t):
        t = min(max(t, 0.0), 1.0)
        return t * t * (3 - 2 * t)

    # 주머니 몸통: 목(좁음)에서 아래로 부드럽게 넓어지는 타원형 실루엣
    top_y, bottom_y = 0.44, 0.82
    center_y, radius_x, radius_y = 0.635, 0.265, 0.185
    left, right = [], []
    steps = 400
    for i in range(steps + 1):
        y = top_y + (bottom_y - top_y) * i / steps
        dy = (y - center_y) / radius_y
        ellipse_hw = radius_x * math.sqrt(max(0.0, 1 - dy * dy)) if y >= center_y else radius_x
        neck_hw = 0.115 + (radius_x - 0.115) * smoothstep((y - top_y) / (center_y - top_y))
        hw = min(ellipse_hw, neck_hw) if y >= center_y else neck_hw
        left.append((cx - hw * S, y * S))
        right.append((cx + hw * S, y * S))
    m.polygon(left + right[::-1], fill=255)
    # 목 부분 주름 (세 갈래)
    for dx in (-0.095, 0.0, 0.095):
        m.ellipse([cx + S * (dx - 0.068), S * 0.255, cx + S * (dx + 0.068), S * 0.445], fill=255)
    # 가장자리 꺾임을 없애기 위해 흐림 후 임계값 처리
    mask = mask.filter(ImageFilter.GaussianBlur(S * 0.006)).point(lambda v: 255 if v > 127 else 0)
    img.paste(gold, (0, 0), mask)

    d = ImageDraw.Draw(img)
    knot_color = top
    # 매듭 띠
    d.rounded_rectangle([cx - S * 0.17, S * 0.415, cx + S * 0.17, S * 0.465], radius=S * 0.025, fill=knot_color)
    # 행운 점 3×3
    r = S * 0.017
    for row in range(3):
        for col in range(3):
            x = cx + (col - 1) * S * 0.07
            y = S * 0.575 + row * S * 0.065
            d.ellipse([x - r, y - r, x + r, y + r], fill=knot_color)

    img = img.filter(ImageFilter.SMOOTH).resize((s, s), Image.LANCZOS)
    return img


def write_icons():
    folder = os.path.join(ROOT, "AppIcon.appiconset")
    os.makedirs(folder, exist_ok=True)
    images = []
    for variant, filename, appearance in (
        ("light", "AppIcon-1024.png", None),
        ("dark", "AppIcon-1024-dark.png", "dark"),
        ("tinted", "AppIcon-1024-tinted.png", "tinted"),
    ):
        draw_icon(1024, variant).save(os.path.join(folder, filename))
        entry = {"filename": filename, "idiom": "universal", "platform": "ios", "size": "1024x1024"}
        if appearance:
            entry["appearances"] = [{"appearance": "luminosity", "value": appearance}]
        images.append(entry)
    write_json(os.path.join(folder, "Contents.json"), {"images": images, "info": INFO})


if __name__ == "__main__":
    write_colors()
    write_icons()
    print(f"색상 {len(COLORS)}개 + AccentColor + LaunchBackground, 앱 아이콘 3종 생성 완료")
