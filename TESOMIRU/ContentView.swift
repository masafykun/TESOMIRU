import SwiftUI

enum AppScreen: Equatable {
    case home
    case capture
    case analyzing(UIImage)
    case result(PalmReadingResult)

    static func == (lhs: AppScreen, rhs: AppScreen) -> Bool {
        switch (lhs, rhs) {
        case (.home, .home), (.capture, .capture): return true
        case (.analyzing, .analyzing), (.result, .result): return true
        default: return false
        }
    }
}

struct ContentView: View {
    @State private var screen: AppScreen = .home
    @State private var capturedImage: UIImage?

    var body: some View {
        ZStack {
            Color.appBg.ignoresSafeArea()

            switch screen {
            case .home:
                HomeView {
                    withAnimation(.easeInOut(duration: 0.35)) {
                        screen = .capture
                    }
                }
                .transition(.asymmetric(
                    insertion: .move(edge: .trailing).combined(with: .opacity),
                    removal: .move(edge: .leading).combined(with: .opacity)
                ))

            case .capture:
                CaptureView(
                    onAnalyze: { image in
                        capturedImage = image
                        withAnimation(.easeInOut(duration: 0.35)) {
                            screen = .analyzing(image)
                        }
                    },
                    onBack: {
                        withAnimation(.easeInOut(duration: 0.35)) {
                            screen = .home
                        }
                    }
                )
                .transition(.asymmetric(
                    insertion: .move(edge: .trailing).combined(with: .opacity),
                    removal: .move(edge: .leading).combined(with: .opacity)
                ))

            case .analyzing(let image):
                AnalyzingView(
                    image: image,
                    onComplete: { result in
                        withAnimation(.easeInOut(duration: 0.35)) {
                            screen = .result(result)
                        }
                    },
                    onError: {
                        withAnimation(.easeInOut(duration: 0.35)) {
                            screen = .capture
                        }
                    }
                )
                .transition(.opacity)

            case .result(let result):
                ResultView(
                    result: result,
                    onRestart: {
                        withAnimation(.easeInOut(duration: 0.35)) {
                            screen = .home
                        }
                    },
                    onRetry: {
                        withAnimation(.easeInOut(duration: 0.35)) {
                            screen = .capture
                        }
                    }
                )
                .transition(.asymmetric(
                    insertion: .move(edge: .trailing).combined(with: .opacity),
                    removal: .move(edge: .leading).combined(with: .opacity)
                ))
            }
        }
    }
}

// MARK: - App Colors
extension Color {
    static let appBg          = Color(red: 0.04, green: 0.03, blue: 0.10)
    static let appCard        = Color(red: 0.10, green: 0.08, blue: 0.20)
    static let appPrimary     = Color(red: 0.49, green: 0.23, blue: 0.93)
    static let appPrimaryLight = Color(red: 0.67, green: 0.54, blue: 0.98)
    static let appGold        = Color(red: 0.96, green: 0.77, blue: 0.18)
    static let appSubtext     = Color(white: 0.58)
}

#Preview {
    ContentView()
}
