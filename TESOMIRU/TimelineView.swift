import SwiftUI

struct TimelineView: View {
    @EnvironmentObject private var store: ReadingStore
    @EnvironmentObject private var paywallStore: StoreManager
    @Environment(\.dismiss) private var dismiss
    @State private var selectedReading: SavedReading?
    @State private var showDeleteAlert: SavedReading?
    @State private var showPaywall = false

    var body: some View {
        ZStack {
            Color.appBg.ignoresSafeArea()
            RadialGradient(
                colors: [Color.appPrimary.opacity(0.15), Color.clear],
                center: .topTrailing,
                startRadius: 0,
                endRadius: 600
            )
            .ignoresSafeArea()

            if !paywallStore.isPremium {
                premiumGate
            } else if store.readings.isEmpty {
                emptyState
            } else {
                timelineList
            }
        }
        .sheet(isPresented: $showPaywall) {
            PaywallSheet {}
        }
        .navigationTitle("鑑定の記録")
        .navigationBarTitleDisplayMode(.large)
        .toolbarBackground(Color.appBg.opacity(0.9), for: .navigationBar)
        .toolbarBackground(.visible, for: .navigationBar)
        .toolbarColorScheme(.dark, for: .navigationBar)
        .sheet(item: $selectedReading) { reading in
            NavigationStack {
                ReadingDetailView(reading: reading)
            }
        }
        .alert(
            "鑑定を削除しますか?",
            isPresented: Binding(
                get: { showDeleteAlert != nil },
                set: { if !$0 { showDeleteAlert = nil } }
            ),
            actions: {
                Button("キャンセル", role: .cancel) {}
                Button("削除", role: .destructive) {
                    if let target = showDeleteAlert {
                        store.delete(readingId: target.id)
                    }
                }
            },
            message: { Text("チャット履歴も削除されます") }
        )
    }

    private var premiumGate: some View {
        VStack(spacing: 20) {
            ZStack {
                Circle()
                    .fill(Color.appGold.opacity(0.12))
                    .frame(width: 90, height: 90)
                Image(systemName: "crown.fill")
                    .font(.system(size: 36))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [Color.appGold, .orange],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
            }
            VStack(spacing: 8) {
                Text("鑑定の記録はプレミアム機能")
                    .font(.system(size: 18, weight: .bold))
                    .foregroundColor(.white)
                Text("プレミアムにアップグレードすると、過去の鑑定結果とAI占い師との会話履歴をすべて閲覧できます")
                    .font(.system(size: 13))
                    .foregroundColor(Color.appSubtext)
                    .multilineTextAlignment(.center)
                    .lineSpacing(3)
            }
            .padding(.horizontal, 24)

            Button {
                showPaywall = true
            } label: {
                HStack(spacing: 8) {
                    Image(systemName: "crown.fill")
                        .font(.system(size: 14))
                    Text("プレミアム鑑定にアップグレード")
                        .font(.system(size: 15, weight: .semibold))
                }
                .foregroundColor(Color.appBg)
                .padding(.horizontal, 28)
                .padding(.vertical, 14)
                .background(
                    LinearGradient(colors: [Color.appGold, .orange], startPoint: .leading, endPoint: .trailing)
                )
                .clipShape(Capsule())
                .shadow(color: Color.appGold.opacity(0.4), radius: 12, y: 6)
            }
            .buttonStyle(.plain)
            .padding(.top, 4)
        }
        .padding()
    }

    private var emptyState: some View {
        VStack(spacing: 18) {
            Image(systemName: "clock.arrow.circlepath")
                .font(.system(size: 56))
                .foregroundStyle(
                    LinearGradient(
                        colors: [Color.appPrimaryLight, Color.appGold],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
            Text("まだ鑑定の記録がありません")
                .font(.system(size: 17, weight: .semibold))
                .foregroundColor(.white)
            Text("ホームから手相を占ってみましょう")
                .font(.system(size: 14))
                .foregroundColor(Color.appSubtext)
        }
        .padding()
    }

    private var timelineList: some View {
        ScrollView {
            LazyVStack(spacing: 14) {
                ForEach(store.readings) { reading in
                    Button {
                        selectedReading = reading
                    } label: {
                        ReadingCard(reading: reading)
                    }
                    .buttonStyle(.plain)
                    .contextMenu {
                        Button(role: .destructive) {
                            showDeleteAlert = reading
                        } label: {
                            Label("削除", systemImage: "trash")
                        }
                    }
                }
            }
            .padding(.horizontal, 20)
            .padding(.top, 16)
            .padding(.bottom, 32)
        }
    }
}

// MARK: - ReadingCard

private struct ReadingCard: View {
    let reading: SavedReading

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(dateText)
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundColor(Color.appGold)
                    Text(relativeText)
                        .font(.system(size: 11))
                        .foregroundColor(Color.appSubtext)
                }
                Spacer()
                if !reading.chatMessages.isEmpty {
                    HStack(spacing: 4) {
                        Image(systemName: "bubble.left.and.bubble.right.fill")
                            .font(.system(size: 11))
                        Text("\(reading.chatMessages.count)")
                            .font(.system(size: 11, weight: .semibold))
                    }
                    .foregroundColor(Color.appPrimaryLight)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color.appPrimary.opacity(0.2))
                    .clipShape(Capsule())
                }
            }

            Text(reading.summary)
                .font(.system(size: 14))
                .foregroundColor(.white.opacity(0.85))
                .lineLimit(3)
                .multilineTextAlignment(.leading)

            HStack(spacing: 16) {
                ForEach(reading.lines.prefix(4), id: \.name) { line in
                    VStack(spacing: 4) {
                        Text(line.name)
                            .font(.system(size: 10))
                            .foregroundColor(Color.appSubtext)
                        Text(String(repeating: "●", count: line.score))
                            .font(.system(size: 9))
                            .foregroundColor(Color.appGold)
                    }
                }
                Spacer()
                Image(systemName: "chevron.right")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(Color.appSubtext)
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.appCard)
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .strokeBorder(Color.white.opacity(0.08), lineWidth: 1)
                )
        )
    }

    private var dateText: String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "ja_JP")
        formatter.dateFormat = "yyyy年M月d日 HH:mm"
        return formatter.string(from: reading.date)
    }

    private var relativeText: String {
        let formatter = RelativeDateTimeFormatter()
        formatter.locale = Locale(identifier: "ja_JP")
        formatter.unitsStyle = .full
        return formatter.localizedString(for: reading.date, relativeTo: Date())
    }
}

#Preview {
    NavigationStack {
        TimelineView()
            .environmentObject(ReadingStore.shared)
    }
}
