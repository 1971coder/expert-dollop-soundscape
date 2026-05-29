import Foundation

/// Per-user learned preferences. Lazy: only created once the user opts into
/// personalisation. Fields are deferred to WP03 (`docs/data-model.md` §4);
/// this stub exists so `AdaptiveProfileRepository` is well-typed in WP02 and
/// the repository surface in `api-contract.md` §2 is satisfied.
public struct AdaptiveProfile: Sendable, Codable, Equatable {
    public let id: UUID
    public let lastUpdated: Date

    public init(id: UUID = UUID(), lastUpdated: Date = Date()) {
        self.id = id
        self.lastUpdated = lastUpdated
    }
}
