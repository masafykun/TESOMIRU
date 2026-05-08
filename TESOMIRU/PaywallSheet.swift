import SwiftUI

struct PaywallSheet: View {
    let onPurchase: () -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var selectedPlan: Plan = .yearly
    @State private var isPurchasing = false

    enum Plan { case monthly, yearly }

    var body: some View {
        ZStack {
            Color.appBg.ignoresSafeArea()
            LinearGradient(
                colors: [Color.appGold.opacity(0.08), Color.appPrimary.opacity(0.08), Color.clear],
                startPoint: .top,
                endPoint: .center
            )
            .ignoresSafeArea()

            VStack(spacing: 0) {
                dragIndicator
                ScrollView {
                    VStack(spacing: 28) {
                        crownHeader
                        featureList
                        planSelector
                        purchaseButton
                        footerLinks
                    }
                    .padding(.horizontal, 24)
                    .padding(.bottom, 40)
                }
            }
        }
        .presentationDetents([.large])
        .presentationDragIndicator(.hidden)
    }

    // MARK: - Sections

    private var dragIndicator: some View {
        Capsule()
            .fill(Color.white.opacity(0.2))
            .frame(width: 36, height: 4)
            .padding(.top, 12)
            .padding(.bottom, 20)
    }

    private var crownHeader: some View {
        VStack(spacing: 14) {
            ZStack {
                Circle()
                    .fill(Color.appGold.opacity(0.12))
                    .frame(width: 80, height: 80)
                Circle()
                    .strokeBorder(Color.appGold.opacity(0.3), lineWidth: 1.5)
                    .frame(width: 80, height: 80)
                Image(systemName: "crown.fill")
                    .font(.system(size: 34))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [Color.appGold, Color.orange],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
            }
            VStack(spacing: 6) {
                Text("プレミアム鑑定")
                    .font(.system(size: 24, weight: .bold))
                    .foregroundColor(.white)
                Text("各線の詳細な運勢をすべて解き明かす")
                    .font(.system(size: 14))
                    .foregroundColor(Color.appSubtext)
                    .multilineTextAlignment(.center)
            }
        }
    }

    private var featureList: some View {
        VStack(spacing: 0) {
            ForEach(features, id: \.title) { feature in
                HStack(spacing: 14) {
                    ZStack {
                        Circle()
                            .fill(Color(uiColor: feature.color).opacity(0.15))
                            .frame(width: 36, height: 36)
                        Image(systemName: feature.icon)
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(Color(uiColor: feature.color))
                    }
                    VStack(alignment: .leading, spacing: 2) {
                        Text(feature.title)
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(.white)
                        Text(feature.description)
                            .font(.system(size: 12))
                            .foregroundColor(Color.appSubtext)
                    }
                    Spacer()
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 18))
                        .foregroundColor(Color.appGold)
                }
                .padding(.vertical, 12)
                if feature.title != features.last?.title {
                    Divider()
                        .overlay(Color.white.opacity(0.06))
                }
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 18)
                .fill(Color.appCard)
                .overlay(
                    RoundedRectangle(cornerRadius: 18)
                        .strokeBorder(Color.white.opacity(0.08), lineWidth: 1)
                )
        )
    }

    private var planSelector: some View {
        VStack(spacing: 10) {
            planButton(
                plan: .yearly,
                title: "年間プラン",
                price: "¥2,400/年",
                sub: "¥200/月 — 58%お得",
                badge: "おすすめ"
            )
            planButton(
                plan: .monthly,
                title: "月額プラン",
                price: "¥480/月",
                sub: nil,
                badge: nil
            )
        }
    }

    private func planButton(plan: Plan, title: String, price: String, sub: String?, badge: String?) -> some View {
        let isSelected = selectedPlan == plan
        return Button {
            withAnimation(.easeInOut(duration: 0.15)) {
                selectedPlan = plan
            }
        } label: {
            HStack(spacing: 12) {
                ZStack {
                    Circle()
                        .strokeBorder(isSelected ? Color.appGold : Color.white.opacity(0.2), lineWidth: isSelected ? 2 : 1)
                        .frame(width: 20, height: 20)
                    if isSelected {
                        Circle()
                            .fill(Color.appGold)
                            .frame(width: 10, height: 10)
                    }
                }
                VStack(alignment: .leading, spacing: 2) {
                    HStack(spacing: 8) {
                        Text(title)
                            .font(.system(size: 15, weight: .semibold))
                            .foregroundColor(.white)
                        if let badge {
                            Text(badge)
                                .font(.system(size: 10, weight: .bold))
                                .foregroundColor(Color.appBg)
                                .padding(.horizontal, 7)
                                .padding(.vertical, 2)
                                .background(Color.appGold)
                                .clipShape(Capsule())
                        }
                    }
                    if let sub {
                        Text(sub)
                            .font(.system(size: 11))
                            .foregroundColor(Color.appGold.opacity(0.8))
                    }
                }
                Spacer()
                Text(price)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(isSelected ? Color.appGold : Color.appSubtext)
            }
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 14)
                    .fill(Color.appCard)
                    .overlay(
                        RoundedRectangle(cornerRadius: 14)
                            .strokeBorder(
                                isSelected ? Color.appGold.opacity(0.5) : Color.white.opacity(0.08),
                                lineWidth: isSelected ? 1.5 : 1
                            )
                    )
            )
        }
        .buttonStyle(.plain)
    }

    private var purchaseButton: some View {
        Button {
            guard !isPurchasing else { return }
            Task {
                isPurchasing = true
                // StoreKit の購入処理をここに実装する
                // モック: 1.5秒後に解除
                try? await Task.sleep(for: .seconds(1.5))
                onPurchase()
                dismiss()
            }
        } label: {
            ZStack {
                HStack(spacing: 8) {
                    if !isPurchasing {
                        Image(systemName: "crown.fill")
                            .font(.system(size: 15))
                        Text(selectedPlan == .yearly ? "年間プランで始める" : "月額プランで始める")
                            .font(.system(size: 17, weight: .semibold))
                    } else {
                        ProgressView()
                            .tint(.white)
                            .scaleEffect(0.9)
                        Text("処理中...")
                            .font(.system(size: 17, weight: .semibold))
                    }
                }
                .foregroundColor(Color.appBg)
                .frame(maxWidth: .infinity)
                .frame(height: 56)
                .background(
                    LinearGradient(
                        colors: [Color.appGold, Color.orange],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .clipShape(Capsule())
                .shadow(color: Color.appGold.opacity(0.4), radius: 14, y: 6)
            }
        }
        .buttonStyle(.plain)
        .disabled(isPurchasing)
    }

    private var footerLinks: some View {
        VStack(spacing: 10) {
            Button("購入を復元する") {}
                .font(.system(size: 13))
                .foregroundColor(Color.appSubtext)
            Button("キャンセル") { dismiss() }
                .font(.system(size: 13))
                .foregroundColor(Color.appSubtext)
            Text("購入はApp Storeアカウントに請求されます。\nサブスクリプションは期間終了の24時間前までに\nキャンセルしない限り自動更新されます。")
                .font(.system(size: 10))
                .foregroundColor(Color.appSubtext.opacity(0.6))
                .multilineTextAlignment(.center)
                .lineSpacing(3)
        }
    }

    // MARK: - Feature data

    private let features: [Feature] = [
        .init(icon: "heart.fill",       color: .systemRed,    title: "生命線の詳細鑑定",  description: "健康・活力・寿命の詳しい読み解き"),
        .init(icon: "waveform.path.ecg", color: .systemBlue,  title: "感情線の詳細鑑定",  description: "恋愛・感受性・人間関係の詳しい読み解き"),
        .init(icon: "lightbulb.fill",   color: .systemGreen,  title: "頭脳線の詳細鑑定",  description: "知性・判断力・才能の詳しい読み解き"),
        .init(icon: "star.fill",        color: .systemYellow, title: "運命線の詳細鑑定",  description: "キャリア・使命・成功への道の詳しい読み解き"),
    ]

    private struct Feature {
        let icon: String
        let color: UIColor
        let title: String
        let description: String
    }
}

#Preview {
    PaywallSheet(onPurchase: {})
}
