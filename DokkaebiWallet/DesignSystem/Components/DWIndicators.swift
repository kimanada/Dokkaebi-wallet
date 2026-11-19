import SwiftUI

/// 예산 진행 막대 (DESIGN_SYSTEM.md §5). 0~79% 딥그린, 80~99% 경고, 100% 이상 위험.
struct DWProgressBar: View {
    let progress: Double
    var tint: Color = DWColor.primary
    var height: CGFloat = 8

    var body: some View {
        GeometryReader { proxy in
            ZStack(alignment: .leading) {
                Capsule().fill(DWColor.subtle)
                Capsule()
                    .fill(tint)
                    .frame(width: proxy.size.width * min(max(progress, 0), 1))
            }
        }
        .frame(height: height)
        .animation(DWMotion.standard, value: progress)
        .accessibilityElement()
        .accessibilityValue("\(Int(progress * 100))퍼센트")
    }
}

/// 읽지 않은 수 배지
struct DWBadge: View {
    let count: Int

    var body: some View {
        Text(count > 99 ? "99+" : "\(count)")
            .font(DWTypography.caption.font.monospacedDigit())
            .foregroundStyle(DWColor.canvas)  // 다크 모드의 밝은 위험 색 위에서도 대비 확보
            .padding(.horizontal, 5)
            .frame(minWidth: 18, minHeight: 18)
            .background(DWColor.danger, in: Capsule())
            .accessibilityHidden(true)
    }
}

/// 선택 칩
struct DWChip: View {
    let title: String
    var systemImage: String?
    var isSelected = false
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: DWSpacing.xs) {
                if let systemImage { Image(systemName: systemImage).font(.caption) }
                Text(title)
            }
            .dwFont(.subheadline, color: isSelected ? DWColor.primary : DWColor.textSecondary)
            .fontWeight(isSelected ? .semibold : .regular)
            .padding(.horizontal, DWSpacing.md)
            .frame(minHeight: 32)
            .background(isSelected ? DWColor.primarySoft : DWColor.surface, in: Capsule())
            .overlay(Capsule().strokeBorder(isSelected ? DWColor.primary : DWColor.border, lineWidth: isSelected ? 1 : 0.5))
            .frame(minHeight: DWSpacing.minTouchTarget)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityAddTraits(isSelected ? .isSelected : [])
        .sensoryFeedback(.selection, trigger: isSelected)
    }
}

/// 작은 태그 (공동/개인, 공개 범위 등)
struct DWTag: View {
    let title: String
    let systemImage: String?
    let foregroundColor: Color
    let backgroundColor: Color

    init(title: String, systemImage: String? = nil,
         foreground: Color = DWColor.textSecondary, background: Color = DWColor.subtle) {
        self.title = title
        self.systemImage = systemImage
        self.foregroundColor = foreground
        self.backgroundColor = background
    }

    var body: some View {
        HStack(spacing: 3) {
            if let systemImage { Image(systemName: systemImage) }
            Text(title)
        }
        .font(DWTypography.caption.font)
        .foregroundStyle(foregroundColor)
        .padding(.horizontal, 6)
        .padding(.vertical, 2)
        .background(backgroundColor, in: RoundedRectangle.dw(6))
    }
}

/// 원형 아바타. 이미지가 없으면 구성원 색 배경에 이름 첫 글자를 표시한다.
struct DWAvatar: View {
    let member: FamilyMember
    var size: CGFloat = 32

    var body: some View {
        // 팔레트 색 위 흰 글자는 대비가 부족한 색이 있어, 연한 팔레트 배경 + 기본 텍스트색을 쓴다.
        Text(member.initial)
            .font(.system(size: size * 0.42, weight: .semibold))
            .foregroundStyle(DWColor.textPrimary)
            .frame(width: size, height: size)
            .background(Color(palette: member.color).opacity(0.28), in: Circle())
            .background(DWColor.surface, in: Circle())
            .overlay(Circle().strokeBorder(DWColor.surface, lineWidth: size > 28 ? 2 : 1.5))
            .accessibilityLabel(member.name)
    }
}

/// 겹쳐 보이는 아바타 묶음. 4명을 넘으면 "+N"
struct DWAvatarStack: View {
    let members: [FamilyMember]
    var size: CGFloat = 24
    var maxVisible = 4

    var body: some View {
        HStack(spacing: -size / 3) {
            ForEach(members.prefix(maxVisible)) { DWAvatar(member: $0, size: size) }
            if members.count > maxVisible {
                Text("+\(members.count - maxVisible)")
                    .font(.system(size: size * 0.38, weight: .semibold))
                    .foregroundStyle(DWColor.textSecondary)
                    .frame(width: size, height: size)
                    .background(DWColor.subtle, in: Circle())
            }
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(members.map(\.name).joined(separator: ", "))
    }
}

/// 카테고리 아이콘: 연한 색 배경의 둥근 사각형 + 색 아이콘
struct CategoryIconView: View {
    let systemImage: String
    let color: PaletteColor
    var size: CGFloat = 36

    var body: some View {
        Image(systemName: systemImage)
            .font(.system(size: size * 0.45, weight: .medium))
            .foregroundStyle(Color(palette: color))
            .frame(width: size, height: size)
            .background(Color(palette: color).opacity(0.15), in: RoundedRectangle.dw(size * 0.28))
            .accessibilityHidden(true)
    }
}

/// 공개 범위 표시. 가족 전체(기본값)는 표시하지 않는다.
struct VisibilityBadge: View {
    let visibility: Visibility

    var body: some View {
        switch visibility {
        case .family:
            EmptyView()
        case .private:
            Image(systemName: "lock.fill")
                .font(.caption2)
                .foregroundStyle(DWColor.textTertiary)
                .accessibilityLabel("나만 보기")
        case .selected:
            Image(systemName: "person.2.fill")
                .font(.caption2)
                .foregroundStyle(DWColor.textTertiary)
                .accessibilityLabel("선택한 구성원에게 공개")
        }
    }
}

/// "샘플 데이터" 안내. 실제 데이터가 연결되지 않은 화면에 반드시 표시한다.
struct MockDataBanner: View {
    var message = "아직 실제 데이터가 연결되지 않아 샘플 데이터를 보여드려요"

    var body: some View {
        HStack(alignment: .top, spacing: DWSpacing.sm) {
            Image(systemName: "sparkles")
                .foregroundStyle(DWColor.gold)
                .accessibilityHidden(true)
            VStack(alignment: .leading, spacing: 2) {
                Text("샘플 데이터").dwFont(.caption, color: DWColor.brown)
                Text(message).dwFont(.footnote, color: DWColor.textSecondary)
            }
            Spacer(minLength: 0)
        }
        .padding(DWSpacing.md)
        .background(DWColor.goldSoft, in: RoundedRectangle.dw(DWRadius.md))
        .accessibilityElement(children: .combine)
    }
}

#Preview("지표와 태그") {
    let data = MockData()
    return VStack(alignment: .leading, spacing: DWSpacing.lg) {
        MockDataBanner()
        DWProgressBar(progress: 0.45)
        DWProgressBar(progress: 0.86, tint: DWColor.warning)
        DWProgressBar(progress: 1.2, tint: DWColor.danger)
        HStack {
            DWChip(title: "전체", isSelected: true) {}
            DWChip(title: "개인", systemImage: "person") {}
            DWBadge(count: 7)
            DWTag(title: "공동", foreground: DWColor.primary, background: DWColor.primarySoft)
            DWTag(title: "개인")
        }
        HStack {
            DWAvatar(member: data.members[0], size: 44)
            DWAvatarStack(members: data.members + data.members, size: 28)
            CategoryIconView(systemImage: "fork.knife", color: .maple)
            VisibilityBadge(visibility: .private)
        }
    }
    .padding()
    .background(DWColor.canvas)
}
