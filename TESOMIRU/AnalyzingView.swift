import SwiftUI

struct AnalyzingView: View {
    let image: UIImage
    let onComplete: (PalmReadingResult) -> Void
    let onError: () -> Void

    @State private var pulse1Scale: CGFloat = 1.0
    @State private var pulse1Opacity: Double = 0.6
    @State private var pulse2Scale: CGFloat = 1.0
    @State private var pulse2Opacity: Double = 0.4
    @State private var handOpacity: Double = 0.0
    @State private var handScale: CGFloat = 0.8
    @State private var statusText = "手相を解析中..."
    @State private var dotCount = 1
    @State private var errorMessage: String?

    private let statusMessages = [
        "手相を解析中",
        "線の特徴を読み取り中",
        "鑑定結果を生成中",
        "もうすぐ完了します",
    ]
    @State private var statusIndex = 0

    var body: some View {
        ZStack {
            blurredBackground
            Color.appBg.opacity(0.75).ignoresSafeArea()

            VStack(spacing: 40) {
                Spacer()
                pulsingAnimation
                statusSection
                Spacer()
            }
        }
        .onAppear {
            startAnimations()
        }
        .task {
            await runAnalysis()
        }
    }

    private var blurredBackground: some View {
        Image(uiImage: image)
            .resizable()
            .scaledToFill()
            .ignoresSafeArea()
            .blur(radius: 30)
            .overlay(Color.appBg.opacity(0.6))
    }

    private var pulsingAnimation: some View {
        ZStack {
            // Outer pulse ring 1
            Circle()
                .stroke(Color.appPrimary.opacity(pulse1Opacity), lineWidth: 1.5)
                .frame(width: 200, height: 200)
                .scaleEffect(pulse1Scale)

            // Outer pulse ring 2
            Circle()
                .stroke(Color.appPrimaryLight.opacity(pulse2Opacity), lineWidth: 1)
                .frame(width: 200, height: 200)
                .scaleEffect(pulse2Scale)

            // Inner glow circle
            Circle()
                .fill(
                    RadialGradient(
                        colors: [Color.appPrimary.opacity(0.3), Color.appCard.opacity(0.9)],
                        center: .center,
                        startRadius: 10,
                        endRadius: 80
                    )
                )
                .frame(width: 150, height: 150)

            // Hand image
            Image(uiImage: image)
                .resizable()
                .scaledToFill()
                .frame(width: 130, height: 130)
                .clipShape(Circle())
                .opacity(handOpacity)
                .scaleEffect(handScale)
                .overlay(
                    Circle()
                        .stroke(Color.appPrimary.opacity(0.5), lineWidth: 2)
                )

            // Scanning line overlay
            ScanLineView()
                .frame(width: 130, height: 130)
                .clipShape(Circle())
        }
    }

    private var statusSection: some View {
        VStack(spacing: 16) {
            if let error = errorMessage {
                VStack(spacing: 12) {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .font(.system(size: 28))
                        .foregroundColor(.orange)
                    Text(error)
                        .font(.system(size: 14))
                        .foregroundColor(Color.appSubtext)
                        .multilineTextAlignment(.center)
                    Button("やり直す", action: onError)
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundColor(Color.appPrimaryLight)
                }
            } else {
                Text(statusMessages[statusIndex] + String(repeating: ".", count: dotCount))
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(.white)
                    .animation(.none, value: statusText)
                    .contentTransition(.numericText())

                Text("しばらくお待ちください")
                    .font(.system(size: 13))
                    .foregroundColor(Color.appSubtext)

                ProgressDotsView()
            }
        }
        .padding(.horizontal, 40)
    }

    private func startAnimations() {
        // Fade in hand image
        withAnimation(.easeIn(duration: 0.5)) {
            handOpacity = 1.0
            handScale = 1.0
        }

        // Pulse ring 1
        withAnimation(.easeOut(duration: 1.8).repeatForever(autoreverses: false)) {
            pulse1Scale = 1.6
            pulse1Opacity = 0.0
        }

        // Pulse ring 2 (offset)
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.9) {
            withAnimation(.easeOut(duration: 1.8).repeatForever(autoreverses: false)) {
                pulse2Scale = 1.6
                pulse2Opacity = 0.0
            }
        }

        // Dot animation
        Timer.scheduledTimer(withTimeInterval: 0.5, repeats: true) { timer in
            dotCount = (dotCount % 3) + 1
        }

        // Status message rotation
        Timer.scheduledTimer(withTimeInterval: 2.5, repeats: true) { timer in
            withAnimation(.easeInOut(duration: 0.4)) {
                statusIndex = (statusIndex + 1) % statusMessages.count
            }
        }
    }

    private func runAnalysis() async {
        do {
            let result = try await PalmReadingService.shared.analyze(image: image)
            onComplete(result)
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}

// MARK: - Scan Line Animation

struct ScanLineView: View {
    @State private var offset: CGFloat = -65

    var body: some View {
        GeometryReader { geo in
            Rectangle()
                .fill(
                    LinearGradient(
                        colors: [Color.clear, Color.appPrimaryLight.opacity(0.5), Color.clear],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .frame(height: 2)
                .offset(y: offset + geo.size.height / 2)
                .onAppear {
                    withAnimation(.linear(duration: 1.6).repeatForever(autoreverses: true)) {
                        offset = 65
                    }
                }
        }
    }
}

// MARK: - Progress Dots

struct ProgressDotsView: View {
    @State private var activeIndex = 0

    var body: some View {
        HStack(spacing: 8) {
            ForEach(0..<3, id: \.self) { i in
                Circle()
                    .fill(i == activeIndex ? Color.appPrimary : Color.white.opacity(0.2))
                    .frame(width: 8, height: 8)
                    .scaleEffect(i == activeIndex ? 1.3 : 1.0)
                    .animation(.easeInOut(duration: 0.3), value: activeIndex)
            }
        }
        .onAppear {
            Timer.scheduledTimer(withTimeInterval: 0.5, repeats: true) { _ in
                activeIndex = (activeIndex + 1) % 3
            }
        }
    }
}

#Preview {
    AnalyzingView(
        image: UIImage(systemName: "hand.raised.fill")!,
        onComplete: { _ in },
        onError: {}
    )
}
