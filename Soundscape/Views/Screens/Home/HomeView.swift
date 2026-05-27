import SwiftUI

struct HomeView: View {
    let engine: AudioEngineControl

    @State private var isPlaying = false
    @State private var masterGain: Float = 0.7
    @State private var startError: String?

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            VStack(spacing: 56) {
                Spacer()

                Button(action: toggle) {
                    Image(systemName: isPlaying ? "stop.circle" : "play.circle")
                        .resizable()
                        .frame(width: 96, height: 96)
                        .foregroundStyle(.white.opacity(0.92))
                }
                .accessibilityLabel(isPlaying ? "Stop" : "Start")
                .buttonStyle(.plain)

                VStack(spacing: 14) {
                    Text("MASTER")
                        .font(.system(size: 11, weight: .medium, design: .monospaced))
                        .tracking(2)
                        .foregroundStyle(.white.opacity(0.55))

                    Slider(value: $masterGain, in: 0...1)
                        .tint(.white.opacity(0.6))
                        .padding(.horizontal, 48)
                        .onChange(of: masterGain) { _, newValue in
                            engine.ingest(ParameterDelta(target: .masterGain, value: newValue))
                        }
                        .accessibilityLabel("Master gain")
                }

                if let startError {
                    Text(startError)
                        .font(.system(size: 12, design: .monospaced))
                        .foregroundStyle(.red.opacity(0.7))
                        .padding(.horizontal, 32)
                        .multilineTextAlignment(.center)
                }

                Spacer()
            }
        }
    }

    private func toggle() {
        Task {
            if isPlaying {
                await engine.stop()
                isPlaying = false
            } else {
                do {
                    try await engine.start(with: ModePreset())
                    engine.ingest(ParameterDelta(target: .masterGain, value: masterGain))
                    isPlaying = true
                    startError = nil
                } catch {
                    startError = "Couldn't start: \(error)"
                }
            }
        }
    }
}

#Preview {
    HomeView(engine: PreviewEngine())
        .preferredColorScheme(.dark)
}

private final class PreviewEngine: AudioEngineControl, @unchecked Sendable {
    func start(with preset: ModePreset) async throws {}
    func stop() async {}
    func ingest(_ delta: ParameterDelta) {}
    var routeIsHeadphones: Bool { false }
}
