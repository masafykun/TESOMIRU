import SwiftUI

/// タイムラインから開く、過去鑑定の詳細ビュー（チャットへの導線あり）
struct ReadingDetailView: View {
    let reading: SavedReading

    @EnvironmentObject private var store: ReadingStore
    @EnvironmentObject private var paywallStore: StoreManager
    @Environment(\.dismiss) private var dismiss

    @State private var showChat = false
    @State private var showPaywall = false

    private var currentReading: SavedReading {
        store.readings.first(where: { $0.id == reading.id }) ?? reading
    }

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
                VStack(spacing: 22) {
                    header
                    summaryCard
                    linesGrid
                    luckySection
                    chatPromptCard
                }
                .padding(.horizontal, 20)
                .padding(.top, 16)
                .padding(.bottom, 32)
            }
        }
        .navigationTitle("鑑定詳細")
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(Color.appBg.opacity(0.9), for: .navigationBar)
        .toolbarBackground(.visible, for: .navigationBar)
        .toolbarColorScheme(.dark, for: .navigationBar)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    showChat = true
                } label: {
                    Image(systemName: "bubble.left.and.bubble.right.fill")
                        .foregroundColor(Color.appGold)
                }
            }
        }
        .navigationDestination(isPresented: $showChat) {
            ChatView(reading: currentReading)
        }
        .sheet(isPresented: $showPaywall) {
            PaywallSheet {}
        }
    }

    // MARK: - Sections

    private var header: some View {
        VStack(spacing: 4) {
            Text(dateText)
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(Color.appGold)
            Text("あなたの手相")
                .font(.system(size: 22, weight: .bold))
                .foregroundColor(.white)
        }
    }

    private var summaryCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 8) {
                Image(systemName: "doc.text.fill")
                    .foregroundColor(Color.appPrimaryLight)
                Text("総合鑑定")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(Color.appPrimaryLight)
            }
            Text(currentReading.summary)
                .font(.system(size: 14))
                .foregroundColor(.white.opacity(0.9))
                .lineSpacing(4)
        }
        .padding(18)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 18)
                .fill(Color.appCard)
                .overlay(
                    RoundedRectangle(cornerRadius: 18)
                        .strokeBorder(Color.appPrimary.opacity(0.3), lineWidth: 1)
                )
        )
    }

    private var linesGrid: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 8) {
                Image(systemName: "hand.raised.fill")
                    .foregroundColor(Color.appPrimaryLight)
                Text("手相の各線")
                    .font(.system(size: 13))
                    .foregroundColor(Color.appSubtext)
            }
            ForEach(currentReading.lines, id: \.name) { line in
                lineCard(line: line)
            }
        }
    }

    private func lineCard(line: SavedReading.Line) -> some View {
        let meta = PalmReadingResult.LineReading.iconMeta(for: line.name)
        return VStack(alignment: .leading, spacing: 10) {
            HStack {
                ZStack {
                    Circle()
                        .fill(Color(uiColor: meta.color).opacity(0.15))
                        .frame(width: 36, height: 36)
                    Image(systemName: meta.icon)
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(Color(uiColor: meta.color))
                }
                Text(line.name)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.white)
                Spacer()
                HStack(spacing: 3) {
                    ForEach(0..<5) { i in
                        Capsule()
                            .fill(i < line.score ? Color(uiColor: meta.color) : Color.white.opacity(0.15))
                            .frame(width: 16, height: 4)
                    }
                }
            }
            Text(line.description)
                .font(.system(size: 13))
                .foregroundColor(.white.opacity(0.85))
                .lineSpacing(3)
        }
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: 14)
                .fill(Color.appCard)
                .overlay(
                    RoundedRectangle(cornerRadius: 14)
                        .strokeBorder(Color.white.opacity(0.08), lineWidth: 1)
                )
        )
    }

    private var luckySection: some View {
        HStack(spacing: 14) {
            luckyCard(title: "ラッキーカラー", value: currentReading.luckyColor, icon: "paintpalette.fill", color: Color.appPrimaryLight)
            luckyCard(title: "ラッキーナンバー", value: "\(currentReading.luckyNumber)", icon: "number.circle.fill", color: Color.appGold)
        }
    }

    private func luckyCard(title: String, value: String, icon: String, color: Color) -> some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.system(size: 28))
                .foregroundColor(color)
            Text(title)
                .font(.system(size: 11))
                .foregroundColor(Color.appSubtext)
            Text(value)
                .font(.system(size: 22, weight: .bold))
                .foregroundColor(color)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 16)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.appCard)
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .strokeBorder(Color.white.opacity(0.08), lineWidth: 1)
                )
        )
    }

    private var chatPromptCard: some View {
        Button {
            showChat = true
        } label: {
            HStack(spacing: 14) {
                ZStack {
                    Circle()
                        .fill(Color.appGold.opacity(0.15))
                        .frame(width: 48, height: 48)
                    Image(systemName: "sparkles")
                        .font(.system(size: 22))
                        .foregroundColor(Color.appGold)
                }
                VStack(alignment: .leading, spacing: 4) {
                    Text("AI 占い師と対話する")
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundColor(.white)
                    if currentReading.chatMessages.isEmpty {
                        Text("この鑑定について追加で質問できます")
                            .font(.system(size: 12))
                            .foregroundColor(Color.appSubtext)
                    } else {
                        Text("\(currentReading.chatMessages.count) 件のメッセージ")
                            .font(.system(size: 12))
                            .foregroundColor(Color.appPrimaryLight)
                    }
                }
                Spacer()
                Image(systemName: "chevron.right")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(Color.appSubtext)
            }
            .padding(16)
            .background(
                LinearGradient(
                    colors: [Color.appPrimary.opacity(0.25), Color.appCard],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
            .clipShape(RoundedRectangle(cornerRadius: 16))
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .strokeBorder(Color.appGold.opacity(0.3), lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
    }

    private var dateText: String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "ja_JP")
        formatter.dateFormat = "yyyy年M月d日 HH:mm"
        return formatter.string(from: currentReading.date)
    }
}
