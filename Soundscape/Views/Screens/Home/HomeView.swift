import SwiftUI

struct HomeView: View {
    @Bindable var sessionManager: SessionStateManager
    @State private var showingHistory = false
    @State private var focusDurationMinutes: Int = 25

    private let focusDurationOptions = [25, 50, 90]

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            VStack(spacing: 32) {
                Spacer()
                Text("AURALFLOW")
                    .font(.system(size: 13, weight: .medium, design: .monospaced))
                    .tracking(5)
                    .foregroundStyle(.white.opacity(0.55))

                VStack(spacing: 14) {
                    modeButton(for: .focus)
                    focusDurationChips
                    modeButton(for: .sleep)
                }
                .padding(.horizontal, 48)

                if case .failed(let reason) = sessionManager.engineState {
                    errorBanner(reason: reason)
                }

                Spacer()

                Button {
                    showingHistory = true
                } label: {
                    Text("HISTORY")
                        .font(.system(size: 11, weight: .medium, design: .monospaced))
                        .tracking(3)
                        .foregroundStyle(.white.opacity(0.5))
                }
                .accessibilityLabel("Open session history")
                .padding(.bottom, 24)
            }
        }
        .sheet(isPresented: $showingHistory) {
            HistoryView()
                .preferredColorScheme(.dark)
        }
        .sheet(
            item: Binding(
                get: { sessionManager.pendingRating },
                set: { newValue in
                    if newValue == nil { sessionManager.dismissRating() }
                }
            )
        ) { session in
            RatingPromptView(session: session) { rating in
                Task { await sessionManager.submitRating(rating) }
            }
            .preferredColorScheme(.dark)
        }
    }

    @ViewBuilder
    private func modeButton(for mode: ModeKind) -> some View {
        let blocked = isModeButtonBlocked
        Button {
            let duration = (mode == .focus) ? focusDurationMinutes * 60 : nil
            Task { await sessionManager.start(mode: mode, targetDuration: duration) }
        } label: {
            Text(mode.displayName.uppercased())
                .font(.system(size: 22, weight: .light))
                .tracking(4)
                .foregroundStyle(.white.opacity(blocked ? 0.4 : 0.92))
                .frame(maxWidth: .infinity)
                .padding(.vertical, 22)
                .overlay(
                    RoundedRectangle(cornerRadius: 2)
                        .stroke(.white.opacity(0.25), lineWidth: 1)
                )
        }
        .buttonStyle(.plain)
        .disabled(blocked)
        .accessibilityLabel("Start \(mode.displayName) session")
        .accessibilityIdentifier("modeButton_\(mode.rawValue)")
    }

    @ViewBuilder
    private var focusDurationChips: some View {
        HStack(spacing: 10) {
            ForEach(focusDurationOptions, id: \.self) { minutes in
                Button {
                    focusDurationMinutes = minutes
                } label: {
                    Text("\(minutes)")
                        .font(.system(size: 12, weight: .medium, design: .monospaced))
                        .tracking(2)
                        .foregroundStyle(.white.opacity(focusDurationMinutes == minutes ? 0.9 : 0.4))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 8)
                        .overlay(
                            RoundedRectangle(cornerRadius: 2)
                                .stroke(
                                    .white.opacity(focusDurationMinutes == minutes ? 0.5 : 0.18),
                                    lineWidth: 1
                                )
                        )
                }
                .buttonStyle(.plain)
                .accessibilityLabel("\(minutes) minutes")
                .accessibilityIdentifier("focusDuration_\(minutes)")
            }
        }
    }

    private var isModeButtonBlocked: Bool {
        switch sessionManager.engineState {
        case .starting, .stopping:
            return true
        case .failed:
            return true
        case .idle, .running:
            return false
        }
    }

    @ViewBuilder
    private func errorBanner(reason: String) -> some View {
        Button {
            sessionManager.dismissFailure()
        } label: {
            Text(reason)
                .font(.system(size: 12, design: .monospaced))
                .foregroundStyle(.red.opacity(0.7))
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)
        }
        .buttonStyle(.plain)
        .accessibilityLabel("Audio error. Tap to dismiss.")
    }
}
