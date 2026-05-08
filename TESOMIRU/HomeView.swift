import SwiftUI

struct HomeView: View {
    let onStart: () -> Void

    @State private var glowRadius: CGFloat = 20
    @State private var glowOpacity: Double = 0.5
    @State private var handScale: CGFloat = 1.0

    var body: some View {
        ZStack {
            backgroundLayer
            VStack(spacing: 0) {
                Spacer()
                handIconSection
                Spacer().frame(height: 40)
                titleSection
                Spacer().frame(height: 60)
                startButton
                Spacer().frame(height: 80)
            }
            .padding(.horizontal, 32)
        }
        .onAppear {
            withAnimation(.easeInOut(duration: 2.0).repeatForever(autoreverses: true)) {
                glowRadius = 40
                glowOpacity = 0.9
                handScale = 1.08
            }
        }
    }

    private var backgroundLayer: some View {
        ZStack {
            Color.appBg.ignoresSafeArea()
            RadialGradient(
                colors: [Color.appPrimary.opacity(0.15), Color.clear],
                center: .top,
                startRadius: 0,
                endRadius: 500
            )
            .ignoresSafeArea()
        }
    }

    private var handIconSection: some View {
        ZStack {
            Circle()
                .fill(Color.appPrimary.opacity(0.12))
                .frame(width: 160, height: 160)
                .blur(radius: glowRadius)
                .opacity(glowOpacity)

            Circle()
                .fill(
                    RadialGradient(
                        colors: [Color.appPrimary.opacity(0.25), Color.appCard.opacity(0.8)],
                        center: .center,
                        startRadius: 10,
                        endRadius: 70
                    )
                )
                .frame(width: 140, height: 140)

            Image(systemName: "hand.raised.fill")
                .resizable()
                .scaledToFit()
                .frame(width: 70, height: 70)
                .foregroundStyle(
                    LinearGradient(
                        colors: [Color.appPrimaryLight, Color.appGold],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .scaleEffect(handScale)
        }
    }

    private var titleSection: some View {
        VStack(spacing: 12) {
            Text("TESOMIRU")
                .font(.system(size: 36, weight: .bold, design: .default))
                .foregroundStyle(
                    LinearGradient(
                        colors: [Color.white, Color.appPrimaryLight],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .tracking(6)

            Text("テソミル")
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(Color.appGold)
                .tracking(4)

            Spacer().frame(height: 16)

            Text("AIが手相を鑑定します")
                .font(.system(size: 18, weight: .semibold))
                .foregroundColor(.white)

            Text("手のひらの写真を撮るだけで\nあなたの手相を詳しく分析します")
                .font(.system(size: 14, weight: .regular))
                .foregroundColor(Color.appSubtext)
                .multilineTextAlignment(.center)
                .lineSpacing(4)
        }
    }

    private var startButton: some View {
        Button(action: onStart) {
            HStack(spacing: 10) {
                Text("手相を占う")
                    .font(.system(size: 17, weight: .semibold))
                Image(systemName: "arrow.right")
                    .font(.system(size: 15, weight: .semibold))
            }
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .frame(height: 56)
            .background(
                LinearGradient(
                    colors: [Color.appPrimary, Color(red: 0.35, green: 0.18, blue: 0.85)],
                    startPoint: .leading,
                    endPoint: .trailing
                )
            )
            .clipShape(Capsule())
            .shadow(color: Color.appPrimary.opacity(0.6), radius: 16, y: 8)
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    HomeView(onStart: {})
}
