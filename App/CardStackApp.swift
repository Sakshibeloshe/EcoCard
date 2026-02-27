import SwiftUI

@main
struct CardStackApp: App {
    @StateObject private var store = AppStore()
    @StateObject private var eventManager = EventModeManager()
    @StateObject private var peerManager = PeerManager()
    @StateObject private var eventPeerManager = EventModePeerManager()

    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding = false

    var body: some Scene {
        WindowGroup {
            RootTabView()
                .environmentObject(store)
                .environmentObject(eventManager)
                .environmentObject(peerManager)
                .environmentObject(eventPeerManager)
                .environment(\.managedObjectContext, PersistenceController.shared.container.viewContext)
                .fullScreenCover(isPresented: .init(
                    get: { !hasCompletedOnboarding },
                    set: { if !$0 { hasCompletedOnboarding = true } }
                )) {
                    OnboardingView()
                        .environmentObject(store)
                }
        }
    }
}
