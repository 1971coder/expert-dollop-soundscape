import SwiftUI

@main
struct AuralFlowApp: App {
    private let engine = AudioEngine()

    var body: some Scene {
        WindowGroup {
            HomeView(engine: engine)
                .preferredColorScheme(.dark)
        }
    }
}
