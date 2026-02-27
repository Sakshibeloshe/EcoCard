import SwiftUI

@MainActor
final class EventModeManager: ObservableObject {
    @Published var isLive: Bool = false
    @Published var eventName: String = ""
    @Published var folderName: String = ""
    @Published var eventCode: String = ""
    @Published var selectedCard: CardModel? = nil
    @Published var isReceiverActive: Bool = false

    /// Generate a random 6-character alphanumeric event code.
    func generateEventCode() {
        let chars = "ABCDEFGHJKLMNPQRSTUVWXYZ23456789"  // no 0/O/1/I to avoid confusion
        eventCode = String((0..<6).map { _ in chars.randomElement()! })
    }

    func goLive(event: String, folder: String, code: String, card: CardModel) {
        eventName = event
        folderName = folder
        eventCode = code
        selectedCard = card
        isLive = true
        isReceiverActive = true
    }

    func stop() {
        isLive = false
        eventName = ""
        folderName = ""
        eventCode = ""
        selectedCard = nil
    }

    func toggleReceiver() {
        isReceiverActive.toggle()
        if !isReceiverActive && isLive {
            stop()
        }
    }
}
