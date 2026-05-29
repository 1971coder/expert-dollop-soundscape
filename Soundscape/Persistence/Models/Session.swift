import Foundation
import SwiftData

/// Persisted record of one listening session.
///
/// Lifecycle: created on tap-start (no `endedAt`), finalised when the user
/// (or scene background, for Sleep) ends the session. Immutable after
/// `endedAt` is set, except for late-arriving ratings (see
/// `SessionRepository.finalize(id:endedAt:rating:)`).
///
/// Per the 2026-05-29 rating-shape decision, `rating` is thumbs-encoded:
/// `5` = thumbs up, `1` = thumbs down, `nil` = skipped.
@Model
public final class Session: Identifiable {
    @Attribute(.unique) public var id: UUID
    public var modeKindRaw: String
    public var startedAt: Date
    public var endedAt: Date?
    public var presetId: UUID?
    public var targetDurationSeconds: Int?
    public var actualDurationSeconds: Int?
    public var rating: Int?
    public var freeTextFeedback: String?

    public init(
        id: UUID = UUID(),
        modeKind: ModeKind,
        startedAt: Date = Date(),
        endedAt: Date? = nil,
        presetId: UUID? = nil,
        targetDurationSeconds: Int? = nil,
        actualDurationSeconds: Int? = nil,
        rating: Int? = nil,
        freeTextFeedback: String? = nil
    ) {
        self.id = id
        self.modeKindRaw = modeKind.rawValue
        self.startedAt = startedAt
        self.endedAt = endedAt
        self.presetId = presetId
        self.targetDurationSeconds = targetDurationSeconds
        self.actualDurationSeconds = actualDurationSeconds
        self.rating = rating
        self.freeTextFeedback = freeTextFeedback
    }

    public var modeKind: ModeKind {
        ModeKind(rawValue: modeKindRaw) ?? .focus
    }
}
