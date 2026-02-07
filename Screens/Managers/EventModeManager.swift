//
//  EventModeManager.swift
//  BeforeUSayIt
//
//  Created by SDC-USER on 07/02/26.
//
import SwiftUI

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

