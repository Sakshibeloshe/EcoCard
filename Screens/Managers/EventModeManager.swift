import SwiftUI

// Lightweight state manager — actual networking lives in EventModePeerManager.
final class EventModeManager: ObservableObject {
    @Published var isLive: Bool = false
    @Published var eventName: String = ""
    @Published var folderName: String = ""

    func goLive(event: String, folder: String) {
        eventName = event
        folderName = folder
        isLive = true
    }

    func stop() {
        isLive = false
        eventName = ""
        folderName = ""
    }
}
