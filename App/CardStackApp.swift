

import SwiftUI

@main
struct CardStackApp: App {
    @StateObject private var store = AppStore()
    @StateObject private var eventManager = EventModeManager()

    var body: some Scene {
        WindowGroup {
            RootTabView()
                .environmentObject(store)
                .environmentObject(eventManager)
                .environment(\.managedObjectContext, PersistenceController.shared.container.viewContext)
        }
    }
}
