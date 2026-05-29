import Combine
import SwiftUI

struct SessionView: View {
    @Bindable var sessionManager: SessionStateManager
    @State private var intensity: Float = 0.7
    @State private var elapsed: TimeInterval = 0

    private let tick = Timer.publish(every: 1, on: .main, in: .common).autoconnect()

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            VStack(spacing: 60) {
                Spacer()

                Text(sessionManager.activeSession?.modeKind.displayName.uppercased() ?? "")
                    .font(.system(size: 13, weight: .medium, design: .monospaced))
                    .tracking(5)
                    .foregroundStyle(.white.opacity(0.55))

                Text(timerDisplay)
                    .font(.system(size: 56, weight: .ultraLight, design: .monospaced))
                    .foregroundStyle(.white.opacity(0.92))
                    .monospacedDigit()
                    .accessibilityLabel(timerAccessibilityLabel)

                VStack(spacing: 14) {
                    Text("INTENSITY")
                        .font(.system(size: 11, weight: .medium, design: .monospaced))
                        .tracking(3)
                        .foregroundStyle(.white.opacity(0.45))
                    Slider(value: $intensity, in: 0...1) { _ in
                        sessionManager.applyIntensity(intensity)
                    }
                    .tint(.white.opacity(0.6))
                    .padding(.horizontal, 48)
                    .accessibilityLabel("Intensity")
                    .accessibilityIdentifier("intensitySlider")
                }
                .onChange(of: intensity) { _, newValue in
                    sessionManager.applyIntensity(newValue)
                }

                Spacer()

                Button {
                    Task { await sessionManager.endCurrentSession() }
                } label: {
                    Text("END")
                        .font(.system(size: 14, weight: .medium, design: .monospaced))
                        .tracking(4)
                        .foregroundStyle(.white.opacity(0.85))
                        .frame(width: 200)
                        .padding(.vertical, 18)
                        .overlay(
                            RoundedRectangle(cornerRadius: 2)
                                .stroke(.white.opacity(0.3), lineWidth: 1)
                        )
                }
                .buttonStyle(.plain)
                .accessibilityIdentifier("endButton")
                .padding(.bottom, 32)
            }
        }
        .onAppear { elapsed = 0 }
        .onReceive(tick) { _ in
            guard let started = sessionManager.activeSession?.startedAt else { return }
            elapsed = Date().timeIntervalSince(started)
            if let target = sessionManager.activeSession?.targetDurationSeconds,
               elapsed >= TimeInterval(target) {
                Task { await sessionManager.endCurrentSession() }
            }
        }
    }

    private var timerDisplay: String {
        let value = displayedSeconds
        return String(format: "%02d:%02d", value / 60, value % 60)
    }

    private var timerAccessibilityLabel: String {
        let value = displayedSeconds
        let m = value / 60
        let s = value % 60
        let prefix = sessionManager.activeSession?.targetDurationSeconds == nil ? "Elapsed" : "Remaining"
        return "\(prefix) \(m) minute\(m == 1 ? "" : "s") \(s) second\(s == 1 ? "" : "s")"
    }

    private var displayedSeconds: Int {
        if let target = sessionManager.activeSession?.targetDurationSeconds {
            return max(0, target - Int(elapsed))
        }
        return Int(elapsed)
    }
}
