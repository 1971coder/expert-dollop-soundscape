import Foundation

/// Protocol-only placeholder per `docs/api-contract.md` §2. The implementation
/// lands with WP03 (adaptive intelligence); WP02 ships only the surface so
/// the dependency graph in `AuralFlowApp` is well-typed.
@MainActor
public protocol AdaptiveProfileRepository: Sendable {
    func current() async throws -> AdaptiveProfile?
    func upsert(_ profile: AdaptiveProfile) async throws
    func delete() async throws
}
