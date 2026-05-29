import SwiftUI

/// Thumbs rating prompt shown after a session ends. Encoding per the 2026-05-29
/// rating decision: thumbs up = 5, thumbs down = 1, skip = nil.
struct RatingPromptView: View {
    let session: Session
    let onSubmit: (Int?) -> Void

    @Environment(\.dismiss) private var dismiss

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            VStack(spacing: 48) {
                Spacer()

                VStack(spacing: 6) {
                    Text("HOW WAS THAT")
                        .font(.system(size: 12, weight: .medium, design: .monospaced))
                        .tracking(4)
                        .foregroundStyle(.white.opacity(0.5))
                    Text(session.modeKind.displayName.uppercased())
                        .font(.system(size: 20, weight: .light))
                        .tracking(4)
                        .foregroundStyle(.white.opacity(0.85))
                }

                HStack(spacing: 56) {
                    Button {
                        onSubmit(1)
                        dismiss()
                    } label: {
                        Image(systemName: "hand.thumbsdown")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 44, height: 44)
                            .foregroundStyle(.white.opacity(0.7))
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel("Thumbs down")
                    .accessibilityIdentifier("ratingThumbsDown")

                    Button {
                        onSubmit(5)
                        dismiss()
                    } label: {
                        Image(systemName: "hand.thumbsup")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 44, height: 44)
                            .foregroundStyle(.white.opacity(0.7))
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel("Thumbs up")
                    .accessibilityIdentifier("ratingThumbsUp")
                }

                Spacer()

                Button {
                    onSubmit(nil)
                    dismiss()
                } label: {
                    Text("SKIP")
                        .font(.system(size: 11, weight: .medium, design: .monospaced))
                        .tracking(3)
                        .foregroundStyle(.white.opacity(0.4))
                }
                .buttonStyle(.plain)
                .accessibilityIdentifier("ratingSkip")
                .padding(.bottom, 32)
            }
        }
    }
}
