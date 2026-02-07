//
//  EventModeSheet.swift
//  BeforeUSayIt
//
//  Created by SDC-USER on 07/02/26.
//


import SwiftUI

struct EventModeSheet: View {
    @EnvironmentObject var eventManager: EventModeManager
    @EnvironmentObject var store: AppStore
    @Environment(\.dismiss) var dismiss

    @State private var eventName: String = ""
    @State private var folderName: String = ""

    var body: some View {
        NavigationStack {
            ZStack {
                Color.black.ignoresSafeArea()

                VStack(alignment: .leading, spacing: 18) {

                    Text("Start Event Mode")
                        .font(.system(size: 34, weight: .bold, design: .rounded))
                        .foregroundColor(.white)

                    Text("Cards received during this event will automatically be grouped.")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(.white.opacity(0.5))

                    VStack(spacing: 14) {

                        TextField("Event name (ex: Hackathon 2026)", text: $eventName)
                            .textFieldStyle(.plain)
                            .padding(16)
                            .background(.ultraThinMaterial)
                            .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))

                        TextField("Folder name (ex: February)", text: $folderName)
                            .textFieldStyle(.plain)
                            .padding(16)
                            .background(.ultraThinMaterial)
                            .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
                    }

                    Spacer()

                    Button {
                        eventManager.goLive(event: eventName, folder: folderName)
                        store.createFolder(name: folderName)
                        dismiss()
                    } label: {
                        Text("Go Live")
                            .font(.system(size: 18, weight: .bold))
                            .foregroundColor(.black)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                            .background(Color.pink)
                            .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
                    }
                    .disabled(eventName.isEmpty || folderName.isEmpty)
                    .opacity(eventName.isEmpty || folderName.isEmpty ? 0.5 : 1)

                }
                .padding(22)
            }
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Close") { dismiss() }
                        .foregroundColor(.white.opacity(0.7))
                }
            }
        }
        .presentationDetents([.medium])
        .applyPresentationCornerRadiusIfAvailable(32)
    }
}
private extension View {
    @ViewBuilder
    func applyPresentationCornerRadiusIfAvailable(_ radius: CGFloat) -> some View {
        if #available(iOS 16.4, *) {
            self.presentationCornerRadius(radius)
        } else {
            self
        }
    }
}

