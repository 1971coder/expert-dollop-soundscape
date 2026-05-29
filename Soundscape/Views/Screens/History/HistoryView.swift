import SwiftData
import SwiftUI

struct HistoryView: View {
    @Environment(\.dismiss) private var dismiss

    @Query(
        sort: [SortDescriptor(\Session.startedAt, order: .reverse)]
    )
    private var sessions: [Session]

    var body: some View {
        NavigationStack {
            ZStack {
                Color.black.ignoresSafeArea()
                content
            }
            .navigationTitle("History")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }
                        .foregroundStyle(.white)
                }
            }
        }
    }

    @ViewBuilder
    private var content: some View {
        if sessions.isEmpty {
            Text("NO SESSIONS YET")
                .font(.system(size: 12, weight: .medium, design: .monospaced))
                .tracking(4)
                .foregroundStyle(.white.opacity(0.4))
                .accessibilityIdentifier("historyEmpty")
        } else {
            List {
                ForEach(sessions) { session in
                    sessionRow(session)
                        .listRowBackground(Color.black)
                        .listRowSeparatorTint(.white.opacity(0.1))
                }
            }
            .listStyle(.plain)
            .scrollContentBackground(.hidden)
            .accessibilityIdentifier("historyList")
        }
    }

    @ViewBuilder
    private func sessionRow(_ session: Session) -> some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(session.modeKind.displayName.uppercased())
                    .font(.system(size: 13, weight: .medium, design: .monospaced))
                    .tracking(3)
                    .foregroundStyle(.white.opacity(0.85))
                Text(session.startedAt.formatted(date: .abbreviated, time: .shortened))
                    .font(.system(size: 11, design: .monospaced))
                    .foregroundStyle(.white.opacity(0.5))
            }
            Spacer()
            durationLabel(for: session)
            ratingLabel(for: session)
                .padding(.leading, 12)
        }
        .padding(.vertical, 6)
    }

    @ViewBuilder
    private func durationLabel(for session: Session) -> some View {
        let total = session.actualDurationSeconds ?? 0
        let minutes = total / 60
        Text(total > 0 ? "\(minutes)m" : "—")
            .font(.system(size: 13, design: .monospaced))
            .foregroundStyle(.white.opacity(0.65))
    }

    @ViewBuilder
    private func ratingLabel(for session: Session) -> some View {
        switch session.rating {
        case 5:
            Image(systemName: "hand.thumbsup.fill")
                .foregroundStyle(.white.opacity(0.7))
                .accessibilityLabel("rated thumbs up")
        case 1:
            Image(systemName: "hand.thumbsdown.fill")
                .foregroundStyle(.white.opacity(0.5))
                .accessibilityLabel("rated thumbs down")
        default:
            Text("·")
                .foregroundStyle(.white.opacity(0.25))
                .accessibilityHidden(true)
        }
    }
}
