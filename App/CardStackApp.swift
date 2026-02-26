

import SwiftUI

@main
struct CardStackApp: App {
    @StateObject private var store = AppStore()
    @StateObject private var eventManager = EventModeManager()
    @StateObject private var peerManager = PeerManager()
    @StateObject private var eventPeerManager = EventModePeerManager()

    var body: some Scene {
        WindowGroup {
            RootTabView()
                .environmentObject(store)
                .environmentObject(eventManager)
                .environmentObject(peerManager)
                .environmentObject(eventPeerManager)
                .environment(\.managedObjectContext, PersistenceController.shared.container.viewContext)
        }
    }
}
