/// The set of user-facing mode kinds AuralFlow ships in this WP.
///
/// `relax` and `walk` land in WP03; do not add them here pre-emptively — the
/// enum is the load-bearing dispatch surface in `SessionStateManager`, `ModePreset`,
/// `Session`, and (later) `AdaptiveController` rules. Adding a case before the
/// behaviour exists invites silent gaps where the new mode renders the wrong
/// preset or files no signals.
nonisolated public enum ModeKind: String, Sendable, Codable, CaseIterable {
    case focus
    case sleep
}

extension ModeKind {
    public var displayName: String {
        switch self {
        case .focus: return "Focus"
        case .sleep: return "Sleep"
        }
    }
}
