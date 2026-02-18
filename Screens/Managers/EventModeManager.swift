//
//  EventModeManager.swift
//  BeforeUSayIt
//
//  Created by SDC-USER on 07/02/26.
//
import SwiftUI

final class EventModeManager: ObservableObject {
    @Published var isLive: Bool = false
    @Published var isReceiverActive: Bool = false
    @Published var eventName: String = ""
    @Published var folderName: String = ""

    func goLive(event: String, folder: String) {
        eventName = event
        folderName = folder
        isLive = true
        isReceiverActive = true // Activating event mode also activates receiver mode
    }

    func stop() {
        isLive = false
        isReceiverActive = false
        eventName = ""
        folderName = ""
    }
    
    func toggleReceiver() {
        isReceiverActive.toggle()
        if !isReceiverActive && isLive {
            stop() // Stop event mode if visibility is turned off? Or keep it?
            // Prompt says "event mode basically means u are receiving data from free"
            // So if event mode is on, receiver mode MUST be on.
        }
    }
}

