import SwiftUI

/// 鑑定結果について AI 占い師と対話する画面
struct ChatView: View {
    let reading: SavedReading

    @EnvironmentObject private var store: ReadingStore
    @EnvironmentObject private var paywallStore: StoreManager
    @Environment(\.dismiss) private var dismiss

    @State private var inputText: String = ""
    @State private var isSending = false
    @State private var errorMessage: String?
    @State private var showPaywall = false
    @FocusState private var inputFocused: Bool

    private let freeMessageLimit = 1

    /// store内の最新状態を取得（メッセージ追加後に反映するため）
    private var currentReading: SavedReading {
        store.readings.first(where: { $0.id == reading.id }) ?? reading
    }

    private var messages: [PalmChatMessage] {
        currentReading.chatMessages
    }

    private var userMessageCount: Int {
        messages.filter { $0.role == .user }.count
    }

    private var canSendFreely: Bool {
        paywallStore.isPremium || userMessageCount < freeMessageLimit
    }

    var body: some View {
        ZStack {
            Color.appBg.ignoresSafeArea()
            VStack(spacing: 0) {
                if messages.isEmpty {
                    emptyState
                } else {
                    messageList
                }

                if let errorMessage {
                    Text(errorMessage)
                        .font(.system(size: 12))
                        .foregroundColor(.red.opacity(0.9))
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 6)
                }

                if canSendFreely {
                    if showSuggestions {
                        suggestionChips
                    }
                    inputBar
                } else {
                    upgradePrompt
                }
            }
        }
        .navigationTitle("AI 占い師と対話")
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(Color.appBg.opacity(0.9), for: .navigationBar)
        .toolbarBackground(.visible, for: .navigationBar)
        .toolbarColorScheme(.dark, for: .navigationBar)
        .sheet(isPresented: $showPaywall) {
            PaywallSheet {}
        }
    }

    // MARK: - Sections

    private var emptyState: some View {
        VStack(spacing: 16) {
            Spacer()
            Image(systemName: "sparkles")
                .font(.system(size: 44))
                .foregroundStyle(
                    LinearGradient(
                        colors: [Color.appGold, Color.appPrimaryLight],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
            Text("あなた専属のAI占い師に\nなんでも聞いてみましょう")
                .font(.system(size: 15, weight: .semibold))
                .foregroundColor(.white)
                .multilineTextAlignment(.center)
            Spacer()
        }
    }

    /// 入力バーの上に常に表示する横スクロールの質問チップ
    private var suggestionChips: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(suggestionPrompts, id: \.self) { suggestion in
                    Button {
                        inputText = suggestion
                        inputFocused = true
                    } label: {
                        HStack(spacing: 4) {
                            Image(systemName: "sparkles")
                                .font(.system(size: 10))
                            Text(suggestion)
                                .font(.system(size: 12))
                                .lineLimit(1)
                        }
                        .foregroundColor(Color.appPrimaryLight)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 7)
                        .background(
                            Capsule()
                                .fill(Color.appCard)
                                .overlay(
                                    Capsule()
                                        .strokeBorder(Color.appPrimary.opacity(0.3), lineWidth: 1)
                                )
                        )
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
        }
    }

    /// 提案を表示すべきか
    /// - 送信中・AIタイピング中は隠す（邪魔にならないように）
    /// - 直近メッセージがユーザー発信のときも隠す（AIの返答待ち）
    private var showSuggestions: Bool {
        guard !isSending else { return false }
        if let last = messages.last, last.role == .user { return false }
        return true
    }

    private var messageList: some View {
        ScrollViewReader { proxy in
            ScrollView {
                LazyVStack(spacing: 12) {
                    ForEach(messages) { message in
                        MessageBubble(message: message)
                            .id(message.id)
                    }
                    if isSending {
                        HStack {
                            ProgressView().tint(Color.appPrimaryLight)
                            Text("AI が考えています...")
                                .font(.system(size: 12))
                                .foregroundColor(Color.appSubtext)
                            Spacer()
                        }
                        .padding(.leading, 16)
                        .padding(.top, 4)
                        .id("typing")
                    }
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 16)
            }
            .onChange(of: messages.count) {
                scrollToBottom(proxy)
            }
            .onChange(of: isSending) {
                scrollToBottom(proxy)
            }
            .onAppear {
                scrollToBottom(proxy)
            }
        }
    }

    private var inputBar: some View {
        VStack(spacing: 0) {
            if !paywallStore.isPremium {
                HStack {
                    Image(systemName: "info.circle")
                        .font(.system(size: 10))
                    Text("無料会話 \(userMessageCount) / \(freeMessageLimit) 回")
                        .font(.system(size: 11))
                    Spacer()
                    Button {
                        showPaywall = true
                    } label: {
                        Text("無制限にする")
                            .font(.system(size: 11, weight: .semibold))
                            .foregroundColor(Color.appGold)
                    }
                }
                .foregroundColor(Color.appSubtext)
                .padding(.horizontal, 16)
                .padding(.top, 8)
            }

            HStack(spacing: 8) {
                TextField("質問を入力...", text: $inputText, axis: .vertical)
                    .lineLimit(1...4)
                    .focused($inputFocused)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 10)
                    .background(
                        RoundedRectangle(cornerRadius: 20)
                            .fill(Color.appCard)
                            .overlay(
                                RoundedRectangle(cornerRadius: 20)
                                    .strokeBorder(Color.white.opacity(0.08), lineWidth: 1)
                            )
                    )
                    .foregroundColor(.white)

                Button {
                    Task { await sendMessage() }
                } label: {
                    Image(systemName: "arrow.up.circle.fill")
                        .font(.system(size: 32))
                        .foregroundStyle(
                            isInputValid && !isSending
                            ? LinearGradient(colors: [Color.appGold, .orange], startPoint: .topLeading, endPoint: .bottomTrailing)
                            : LinearGradient(colors: [Color.gray.opacity(0.4), Color.gray.opacity(0.4)], startPoint: .top, endPoint: .bottom)
                        )
                }
                .disabled(!isInputValid || isSending)
            }
            .padding(.horizontal, 12)
            .padding(.top, 8)
            .padding(.bottom, 12)
        }
        .background(Color.appBg)
    }

    private var upgradePrompt: some View {
        VStack(spacing: 12) {
            HStack(spacing: 8) {
                Image(systemName: "crown.fill")
                    .foregroundColor(Color.appGold)
                Text("無料会話は\(freeMessageLimit)回までです")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.white)
            }
            Text("プレミアム鑑定にアップグレードすると、無制限にAI占い師と対話できます。")
                .font(.system(size: 12))
                .foregroundColor(Color.appSubtext)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 24)
            Button {
                showPaywall = true
            } label: {
                Text("プレミアム鑑定にアップグレード")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(Color.appBg)
                    .padding(.horizontal, 24)
                    .padding(.vertical, 12)
                    .background(
                        LinearGradient(colors: [Color.appGold, .orange], startPoint: .leading, endPoint: .trailing)
                    )
                    .clipShape(Capsule())
            }
        }
        .padding(.vertical, 16)
        .frame(maxWidth: .infinity)
        .background(Color.appBg)
    }

    // MARK: - Actions

    private var isInputValid: Bool {
        !inputText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    private func sendMessage() async {
        let trimmed = inputText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }

        let userMsg = PalmChatMessage(role: .user, content: trimmed)
        store.appendChat(to: reading.id, message: userMsg)
        inputText = ""
        errorMessage = nil
        isSending = true

        defer { isSending = false }

        do {
            let history = messages
            let reply = try await PalmReadingService.shared.chat(
                reading: currentReading.toResult(),
                history: history,
                message: trimmed
            )
            let assistantMsg = PalmChatMessage(role: .assistant, content: reply)
            store.appendChat(to: reading.id, message: assistantMsg)
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    private func scrollToBottom(_ proxy: ScrollViewProxy) {
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
            if isSending {
                withAnimation(.easeOut(duration: 0.2)) {
                    proxy.scrollTo("typing", anchor: .bottom)
                }
            } else if let last = messages.last {
                withAnimation(.easeOut(duration: 0.2)) {
                    proxy.scrollTo(last.id, anchor: .bottom)
                }
            }
        }
    }

    private let suggestionPrompts = [
        "今月、特に気をつけることは?",
        "運命線を伸ばすにはどうしたら良い?",
        "私の強みと弱みを教えて",
        "恋愛運を上げるには?",
    ]
}

// MARK: - MessageBubble

private struct MessageBubble: View {
    let message: PalmChatMessage

    var body: some View {
        HStack(alignment: .top, spacing: 8) {
            if message.role == .user {
                Spacer(minLength: 40)
                bubble
                    .background(
                        LinearGradient(colors: [Color.appPrimary, Color.appPrimary.opacity(0.8)], startPoint: .topLeading, endPoint: .bottomTrailing)
                    )
                    .foregroundColor(.white)
                    .clipShape(.rect(cornerRadii: .init(topLeading: 18, bottomLeading: 18, bottomTrailing: 4, topTrailing: 18)))
            } else {
                ZStack {
                    Circle()
                        .fill(Color.appGold.opacity(0.15))
                        .frame(width: 28, height: 28)
                    Image(systemName: "sparkles")
                        .font(.system(size: 12))
                        .foregroundColor(Color.appGold)
                }
                bubble
                    .background(Color.appCard)
                    .foregroundColor(.white)
                    .clipShape(.rect(cornerRadii: .init(topLeading: 4, bottomLeading: 18, bottomTrailing: 18, topTrailing: 18)))
                Spacer(minLength: 40)
            }
        }
    }

    private var bubble: some View {
        Text(message.content)
            .font(.system(size: 14))
            .padding(.horizontal, 14)
            .padding(.vertical, 10)
            .multilineTextAlignment(.leading)
            .fixedSize(horizontal: false, vertical: true)
    }
}

#Preview {
    NavigationStack {
        ChatView(reading: SavedReading(
            id: UUID(),
            date: Date(),
            summary: "あなたの手相はバランスが取れています",
            lines: [],
            luckyColor: "青",
            luckyNumber: 7,
            chatMessages: []
        ))
        .environmentObject(ReadingStore.shared)
        .environmentObject(StoreManager())
    }
}
