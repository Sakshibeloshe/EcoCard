

import SwiftUI

@main
struct CardStackApp: App {
    @StateObject private var store = AppStore()
    @StateObject private var eventManager = EventModeManager()
    @StateObject private var peerManager = PeerManager()

    var body: some Scene {
        WindowGroup {
            RootTabView()
                .environmentObject(store)
                .environmentObject(eventManager)
                .environmentObject(peerManager)
                .environment(\.managedObjectContext, PersistenceController.shared.container.viewContext)
        }
    }
}
