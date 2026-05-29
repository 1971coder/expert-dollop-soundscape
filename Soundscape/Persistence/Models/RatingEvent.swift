import Foundation
import SwiftData

/// One rating event for a `Session`. Per the 2026-05-29 rating decision, MVP
/// values are `5` (thumbs up) or `1` (thumbs down); skipping persists no
/// `RatingEvent` and leaves `Session.rating` nil. The entity exists separately
/// from `Session.rating` so in-session rating events can be added later
/// without migrating `Session`.
@Model
public final class RatingEvent {
    @Attribute(.unique) public var id: UUID
    public var sessionId: UUID
    public var timestamp: Date
    public var value: Int
    public var note: String?

    public init(
        id: UUID = UUID(),
        sessionId: UUID,
        timestamp: Date = Date(),
        value: Int,
        note: String? = nil
    ) {
        self.id = id
        self.sessionId = sessionId
        self.timestamp = timestamp
        self.value = value
        self.note = note
    }
}
