import SwiftUI

struct ResultView: View {
    let result: PalmReadingResult
    let onRestart: () -> Void
    let onRetry: () -> Void

    @State private var appeared = false
    @State private var cardOpacities: [Double] = Array(repeating: 0, count: 6)
    @State private var selectedLine: PalmReadingResult.LineReading?
    @State private var isPremium = false
    @State private var showPaywall = false

    var body: some View {
        ZStack {
            Color.appBg.ignoresSafeArea()
            RadialGradient(
                colors: [Color.appPrimary.opacity(0.12), Color.clear],
                center: .top,
                startRadius: 0,
                endRadius: 500
            )
            .ignoresSafeArea()

            ScrollView {
                VStack(spacing: 24) {
                    header
                        .opacity(cardOpacities[0])
                    summaryCard
                        .opacity(cardOpacities[1])
                    linesGrid
                        .opacity(cardOpacities[2])
                    luckySection
                        .opacity(cardOpacities[3])
                    actionButtons
                        .opacity(cardOpacities[4])
                }
                .padding(.horizontal, 20)
                .padding(.top, 20)
                .padding(.bottom, 48)
            }
        }
        .onAppear {
            animateIn()
        }
        .sheet(item: $selectedLine) { line in
            LineDetailSheet(line: line)
        }
        .sheet(isPresented: $showPaywall) {
            PaywallSheet {
                isPremium = true
            }
        }
    }

    // MARK: - Header

    private var header: some View {
        VStack(spacing: 6) {
            HStack(spacing: 8) {
                Image(systemName: "sparkles")
                    .font(.system(size: 16))
                    .foregroundColor(Color.appGold)
                Text("手相診断結果")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(Color.appGold)
                    .tracking(2)
                Image(systemName: "sparkles")
                    .font(.system(size: 16))
                    .foregroundColor(Color.appGold)
            }
            Text("あなたの手相")
                .font(.system(size: 30, weight: .bold))
                .foregroundStyle(
                    LinearGradient(
                        colors: [.white, Color.appPrimaryLight],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
        }
        .padding(.top, 8)
    }

    // MARK: - Summary

    private var summaryCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(spacing: 8) {
                Image(systemName: "doc.text.fill")
                    .font(.system(size: 14))
                    .foregroundColor(Color.appPrimaryLight)
                Text("総合鑑定")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(Color.appPrimaryLight)
                    .tracking(1)
            }
            Text(result.summary)
                .font(.system(size: 14, weight: .regular))
                .foregroundColor(Color(white: 0.88))
                .lineSpacing(6)
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(Color.appCard)
                .overlay(
                    RoundedRectangle(cornerRadius: 20)
                        .strokeBorder(
                            LinearGradient(
                                colors: [Color.appPrimary.opacity(0.5), Color.appPrimaryLight.opacity(0.2)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 1
                        )
                )
        )
    }

    // MARK: - Lines Grid

    private var linesGrid: some View {
        VStack(spacing: 12) {
            HStack(spacing: 8) {
                Image(systemName: "hand.raised.fill")
                    .font(.system(size: 13))
                    .foregroundColor(Color.appSubtext)
                Text("手相の各線")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(Color.appSubtext)
                    .tracking(1)
                Spacer()
            }
            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                ForEach(result.lines) { line in
                    LineReadingCard(line: line, locked: !isPremium) {
                        if isPremium {
                            selectedLine = line
                        } else {
                            showPaywall = true
                        }
                    }
                }
            }
        }
    }

    // MARK: - Lucky Section

    private var luckySection: some View {
        HStack(spacing: 12) {
            luckyItem(
                icon: "paintpalette.fill",
                title: "ラッキーカラー",
                value: result.luckyColor,
                gradient: [Color.appPrimary, Color.appPrimaryLight]
            )
            luckyItem(
                icon: "number.circle.fill",
                title: "ラッキーナンバー",
                value: "\(result.luckyNumber)",
                gradient: [Color.appGold, Color.orange]
            )
        }
    }

    private func luckyItem(icon: String, title: String, value: String, gradient: [Color]) -> some View {
        VStack(spacing: 10) {
            Image(systemName: icon)
                .font(.system(size: 24))
                .foregroundStyle(LinearGradient(colors: gradient, startPoint: .topLeading, endPoint: .bottomTrailing))

            Text(title)
                .font(.system(size: 11, weight: .medium))
                .foregroundColor(Color.appSubtext)
                .tracking(0.5)

            Text(value)
                .font(.system(size: 28, weight: .bold))
                .foregroundStyle(LinearGradient(colors: gradient, startPoint: .topLeading, endPoint: .bottomTrailing))
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 20)
        .background(
            RoundedRectangle(cornerRadius: 18)
                .fill(Color.appCard)
                .overlay(
                    RoundedRectangle(cornerRadius: 18)
                        .strokeBorder(Color.white.opacity(0.08), lineWidth: 1)
                )
        )
    }

    // MARK: - Action Buttons

    private var actionButtons: some View {
        VStack(spacing: 12) {
            Button(action: onRetry) {
                HStack(spacing: 8) {
                    Image(systemName: "camera.fill")
                        .font(.system(size: 15))
                    Text("別の写真で占う")
                        .font(.system(size: 16, weight: .semibold))
                }
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .frame(height: 54)
                .background(
                    LinearGradient(
                        colors: [Color.appPrimary, Color(red: 0.35, green: 0.18, blue: 0.85)],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .clipShape(Capsule())
                .shadow(color: Color.appPrimary.opacity(0.5), radius: 14, y: 6)
            }
            .buttonStyle(.plain)

            Button(action: onRestart) {
                HStack(spacing: 8) {
                    Image(systemName: "house.fill")
                        .font(.system(size: 14))
                    Text("ホームに戻る")
                        .font(.system(size: 15, weight: .medium))
                }
                .foregroundColor(Color.appSubtext)
                .frame(maxWidth: .infinity)
                .frame(height: 44)
            }
            .buttonStyle(.plain)
        }
    }

    // MARK: - Animation

    private func animateIn() {
        for i in 0..<cardOpacities.count {
            DispatchQueue.main.asyncAfter(deadline: .now() + Double(i) * 0.15) {
                withAnimation(.easeOut(duration: 0.5)) {
                    cardOpacities[i] = 1.0
                }
            }
        }
    }
}

// MARK: - Line Reading Card

struct LineReadingCard: View {
    let line: PalmReadingResult.LineReading
    let locked: Bool
    let onTap: () -> Void

    var lineColor: Color { Color(uiColor: line.iconColor) }

    var body: some View {
        Button(action: onTap) {
            VStack(alignment: .leading, spacing: 12) {
                // ヘッダー（常に表示）
                HStack(spacing: 8) {
                    ZStack {
                        Circle()
                            .fill(lineColor.opacity(locked ? 0.08 : 0.15))
                            .frame(width: 34, height: 34)
                        Image(systemName: locked ? "lock.fill" : line.icon)
                            .font(.system(size: 15, weight: .semibold))
                            .foregroundColor(locked ? Color.appSubtext : lineColor)
                    }
                    Text(line.name)
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundColor(locked ? Color.appSubtext : .white)
                    Spacer()
                    Image(systemName: locked ? "lock.fill" : "chevron.right")
                        .font(.system(size: 10, weight: locked ? .regular : .semibold))
                        .foregroundColor(Color.appSubtext)
                }

                if locked {
                    lockedContent
                } else {
                    unlockedContent
                }
            }
            .padding(14)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color.appCard)
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .strokeBorder(
                                locked ? Color.white.opacity(0.08) : lineColor.opacity(0.25),
                                lineWidth: 1
                            )
                    )
            )
        }
        .buttonStyle(CardPressStyle())
    }

    private var lockedContent: some View {
        VStack(spacing: 6) {
            // ぼかしたダミーバー
            VStack(spacing: 5) {
                ForEach(0..<3, id: \.self) { i in
                    RoundedRectangle(cornerRadius: 3)
                        .fill(Color.white.opacity(0.07))
                        .frame(height: 6)
                        .frame(maxWidth: i == 2 ? .infinity * 0.6 : .infinity)
                }
            }
            .blur(radius: 3)

            HStack(spacing: 4) {
                Image(systemName: "crown.fill")
                    .font(.system(size: 9))
                    .foregroundColor(Color.appGold)
                Text("プレミアムで解除")
                    .font(.system(size: 10, weight: .medium))
                    .foregroundColor(Color.appGold)
            }
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(Color.appGold.opacity(0.12))
            .clipShape(Capsule())
        }
    }

    private var unlockedContent: some View {
        VStack(alignment: .leading, spacing: 8) {
            ScoreView(score: line.score, color: lineColor)
            Text(line.description)
                .font(.system(size: 11, weight: .regular))
                .foregroundColor(Color(white: 0.72))
                .lineSpacing(3)
                .lineLimit(3)
                .multilineTextAlignment(.leading)
            Text("続きを読む")
                .font(.system(size: 10, weight: .medium))
                .foregroundColor(lineColor.opacity(0.8))
        }
    }
}

struct CardPressStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.97 : 1.0)
            .animation(.easeInOut(duration: 0.12), value: configuration.isPressed)
    }
}

// MARK: - Line Detail Sheet

struct LineDetailSheet: View {
    let line: PalmReadingResult.LineReading
    @Environment(\.dismiss) private var dismiss

    var lineColor: Color { Color(uiColor: line.iconColor) }

    var body: some View {
        ZStack {
            Color.appBg.ignoresSafeArea()
            RadialGradient(
                colors: [lineColor.opacity(0.12), Color.clear],
                center: .top,
                startRadius: 0,
                endRadius: 350
            )
            .ignoresSafeArea()

            VStack(spacing: 0) {
                // ドラッグインジケーター
                Capsule()
                    .fill(Color.white.opacity(0.2))
                    .frame(width: 36, height: 4)
                    .padding(.top, 12)
                    .padding(.bottom, 24)

                ScrollView {
                    VStack(spacing: 28) {
                        // アイコン
                        ZStack {
                            Circle()
                                .fill(lineColor.opacity(0.15))
                                .frame(width: 80, height: 80)
                            Circle()
                                .strokeBorder(lineColor.opacity(0.3), lineWidth: 1.5)
                                .frame(width: 80, height: 80)
                            Image(systemName: line.icon)
                                .font(.system(size: 34, weight: .semibold))
                                .foregroundColor(lineColor)
                        }

                        // タイトルとスコア
                        VStack(spacing: 10) {
                            Text(line.name)
                                .font(.system(size: 26, weight: .bold))
                                .foregroundColor(.white)
                            ScoreView(score: line.score, color: lineColor)
                        }

                        // 説明テキスト
                        Text(line.description)
                            .font(.system(size: 15, weight: .regular))
                            .foregroundColor(Color(white: 0.85))
                            .lineSpacing(8)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 8)

                        Spacer().frame(height: 20)
                    }
                    .padding(.horizontal, 28)
                    .padding(.bottom, 40)
                }
            }
        }
        .presentationDetents([.medium, .large])
        .presentationDragIndicator(.hidden)
    }
}

// MARK: - Score View

struct ScoreView: View {
    let score: Int
    let color: Color
    let maxScore = 5

    var body: some View {
        HStack(spacing: 4) {
            ForEach(1...maxScore, id: \.self) { i in
                RoundedRectangle(cornerRadius: 2)
                    .fill(i <= score ? color : Color.white.opacity(0.12))
                    .frame(width: 18, height: 4)
            }
        }
    }
}

#Preview {
    ResultView(
        result: PalmReadingResult(
            summary: "あなたの手相は非常にバランスが取れています。知性と感情の調和が見事で、人生において多くの成功を収めるでしょう。",
            lines: [
                .init(name: "生命線", icon: "heart.fill", iconColor: .systemRed, description: "力強く長い生命線で、生命力と活力に満ちています。", score: 5),
                .init(name: "感情線", icon: "waveform.path.ecg", iconColor: .systemBlue, description: "深く鮮明な感情線は豊かな感受性を示しています。", score: 4),
                .init(name: "頭脳線", icon: "lightbulb.fill", iconColor: .systemGreen, description: "明瞭で長い頭脳線は優れた知性を示しています。", score: 4),
                .init(name: "運命線", icon: "star.fill", iconColor: .systemYellow, description: "はっきりとした運命線が中央を走っています。", score: 5),
            ],
            luckyColor: "紫",
            luckyNumber: 7
        ),
        onRestart: {},
        onRetry: {}
    )
}
