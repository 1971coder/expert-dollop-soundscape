import Foundation
import SwiftData

public enum SessionRepositoryError: Error, Sendable, Equatable {
    case notFound(UUID)
}

@MainActor
public protocol SessionRepository: Sendable {
    func create(_ session: Session) async throws
    func finalize(id: UUID, endedAt: Date, rating: Int?) async throws
    func list(limit: Int, offset: Int) async throws -> [Session]
    func purgeAll() async throws
}

@MainActor
public final class SwiftDataSessionRepository: SessionRepository {
    private let container: ModelContainer

    public init(container: ModelContainer) {
        self.container = container
    }

    public func create(_ session: Session) async throws {
        let context = container.mainContext
        context.insert(session)
        try context.save()
    }

    public func finalize(id: UUID, endedAt: Date, rating: Int?) async throws {
        let context = container.mainContext
        var descriptor = FetchDescriptor<Session>(predicate: #Predicate { $0.id == id })
        descriptor.fetchLimit = 1
        guard let session = try context.fetch(descriptor).first else {
            throw SessionRepositoryError.notFound(id)
        }
        session.endedAt = endedAt
        session.actualDurationSeconds = max(0, Int(endedAt.timeIntervalSince(session.startedAt)))
        if let rating { session.rating = rating }
        try context.save()
    }

    public func list(limit: Int, offset: Int) async throws -> [Session] {
        let context = container.mainContext
        var descriptor = FetchDescriptor<Session>(
            sortBy: [SortDescriptor(\.startedAt, order: .reverse)]
        )
        descriptor.fetchLimit = limit
        descriptor.fetchOffset = offset
        return try context.fetch(descriptor)
    }

    public func purgeAll() async throws {
        let context = container.mainContext
        try context.delete(model: Session.self)
        try context.delete(model: RatingEvent.self)
        try context.save()
    }
}
