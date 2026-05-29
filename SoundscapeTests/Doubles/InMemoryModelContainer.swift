import Foundation
import SwiftData

@testable import Soundscape

@MainActor
enum InMemoryModelContainer {
    static func make() throws -> ModelContainer {
        let schema = Schema([Session.self, ModePresetRecord.self, RatingEvent.self])
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        return try ModelContainer(for: schema, configurations: config)
    }
}
