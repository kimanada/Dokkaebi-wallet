import SwiftUI
import UIKit

/// 바코드 전체 화면 (FR-WAL-05).
/// 흰 배경을 유지하고(인식률), 화면 밝기를 최대로 올린 뒤 닫을 때 원래대로 돌려놓는다.
struct BarcodeFullScreenView: View {
    let card: WalletCard
    @Environment(\.dismiss) private var dismiss
    @State private var originalBrightness: CGFloat?

    var body: some View {
        VStack(spacing: DWSpacing.xl) {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text(card.brandName).font(.system(.title2, weight: .bold))
                    if let name = card.cardName { Text(name).font(.subheadline).foregroundStyle(.black.opacity(0.6)) }
                }
                Spacer()
                Button {
                    dismiss()
                } label: {
                    Image(systemName: "xmark")
                        .font(.headline)
                        .frame(width: DWSpacing.minTouchTarget, height: DWSpacing.minTouchTarget)
                        .background(.black.opacity(0.06), in: Circle())
                }
                .accessibilityLabel("닫기")
            }
            Spacer()
            barcode
            if let number = card.formattedNumber {
                Text(number)
                    .font(.system(.title2, design: .monospaced, weight: .semibold))
                    .minimumScaleFactor(0.6)
                    .lineLimit(1)
                    .textSelection(.enabled)
            }
            if card.barcodeType.isLinear {
                Label("기기를 가로로 돌리면 더 크게 보여요", systemImage: "rotate.right")
                    .font(.footnote)
                    .foregroundStyle(.black.opacity(0.55))
            }
            Spacer()
            if let memo = card.memo {
                Text(memo).font(.footnote).foregroundStyle(.black.opacity(0.6))
            }
        }
        .foregroundStyle(.black)
        .padding(DWSpacing.xxl)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        // 다크 모드에서도 흰 배경 고정 (DESIGN_SYSTEM.md §5 FullScreenBarcode)
        .background(Color.white.ignoresSafeArea())
        .environment(\.colorScheme, .light)
        .onAppear(perform: brighten)
        .onDisappear(perform: restore)
    }

    @ViewBuilder
    private var barcode: some View {
        if let value = card.barcodeValue,
           let image = try? BarcodeGenerator.image(for: value, type: card.barcodeType) {
            Image(uiImage: image)
                .interpolation(.none)
                .resizable()
                .scaledToFit()
                .frame(maxWidth: card.barcodeType.isLinear ? .infinity : 280)
                .padding(.horizontal, card.barcodeType.isLinear ? 0 : DWSpacing.xl)
                .accessibilityLabel("\(card.barcodeType.displayName), 번호 \(value)")
        } else {
            VStack(spacing: DWSpacing.md) {
                Image(systemName: "barcode")
                    .font(.system(size: 64))
                    .foregroundStyle(.black.opacity(0.3))
                Text("\(card.barcodeType.displayName) 바코드 표시는 다음 단계에서 지원돼요")
                    .font(.subheadline)
                    .multilineTextAlignment(.center)
                    .foregroundStyle(.black.opacity(0.6))
                Text("아래 번호를 직원에게 보여주세요")
                    .font(.footnote)
                    .foregroundStyle(.black.opacity(0.5))
            }
            .frame(maxWidth: .infinity, minHeight: 180)
            .background(.black.opacity(0.04), in: RoundedRectangle.dw(DWRadius.lg))
        }
    }

    private var screen: UIScreen? {
        UIApplication.shared.connectedScenes
            .compactMap { $0 as? UIWindowScene }
            .first { $0.activationState == .foregroundActive }?
            .screen
    }

    private func brighten() {
        UIApplication.shared.isIdleTimerDisabled = true
        guard let screen else { return }
        originalBrightness = screen.brightness
        screen.brightness = 1.0
    }

    private func restore() {
        UIApplication.shared.isIdleTimerDisabled = false
        if let originalBrightness, let screen { screen.brightness = originalBrightness }
    }
}

#Preview("바코드 - QR") {
    BarcodeFullScreenView(card: MockData().cards[1])
}

#Preview("바코드 - EAN-13 (미지원)") {
    BarcodeFullScreenView(card: MockData().cards[0])
}
