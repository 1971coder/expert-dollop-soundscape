import SwiftData
import SwiftUI
import os

@main
struct AuralFlowApp: App {
    @State private var dependencies = AppDependencies()

    var body: some Scene {
        WindowGroup {
            RootView(dependencies: dependencies)
                .preferredColorScheme(.dark)
        }
        .modelContainer(dependencies.modelContainer)
    }
}

@MainActor
@Observable
final class AppDependencies {
    let modelContainer: ModelContainer
    let engine: AudioEngine
    let sessionRepo: SwiftDataSessionRepository
    let presetRepo: SwiftDataPresetRepository
    let sessionManager: SessionStateManager

    private static let logger = Logger(subsystem: "app.auralflow", category: "app.bootstrap")

    init() {
        let schema = Schema([Session.self, ModePresetRecord.self, RatingEvent.self])
        let isUITest = CommandLine.arguments.contains("-uitest-clean-state")
        let config = ModelConfiguration(schema: schema, isStoredInMemoryOnly: isUITest)
        do {
            self.modelContainer = try ModelContainer(for: schema, configurations: [config])
        } catch {
            Self.logger.fault("ModelContainer init failed: \(String(describing: error), privacy: .public)")
            fatalError("ModelContainer init failed: \(error)")
        }
        self.engine = AudioEngine()
        let sessionRepo = SwiftDataSessionRepository(container: modelContainer)
        let presetRepo = SwiftDataPresetRepository(container: modelContainer)
        self.sessionRepo = sessionRepo
        self.presetRepo = presetRepo
        self.sessionManager = SessionStateManager(engine: engine, sessionRepo: sessionRepo)
        Task { @MainActor in
            await Self.seedFactoryPresets(into: presetRepo)
        }
    }

    private static func seedFactoryPresets(into repo: any PresetRepository) async {
        for preset in FocusPresets.all + SleepPresets.all {
            do {
                try await repo.save(preset)
            } catch {
                logger.error("preset seed failed: \(String(describing: error), privacy: .public)")
            }
        }
    }
}

struct RootView: View {
    @Bindable var dependencies: AppDependencies

    var body: some View {
        switch dependencies.sessionManager.engineState {
        case .running:
            SessionView(sessionManager: dependencies.sessionManager)
        default:
            HomeView(sessionManager: dependencies.sessionManager)
        }
    }
}
