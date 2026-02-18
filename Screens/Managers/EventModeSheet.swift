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
        ZStack {
            Color.obsidianBlack.ignoresSafeArea()

            VStack(spacing: 32) {
                // Top Bolt Icon (Image 3)
                ZStack {
                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                        .fill(Color.softRose)
                        .frame(width: 64, height: 64)
                    
                    Image(systemName: "bolt.fill")
                        .font(.system(size: 32, weight: .bold))
                        .foregroundColor(.black)
                }
                .padding(.top, 40)

                VStack(spacing: 8) {
                    Text("Event Setup")
                        .font(.system(size: 28, weight: .bold, design: .rounded))
                        .foregroundColor(.white)
                    
                    Text("ORGANIZE YOUR CONNECTIONS")
                        .font(.system(size: 12, weight: .bold, design: .rounded))
                        .foregroundColor(.white.opacity(0.3))
                        .tracking(2)
                }

                VStack(alignment: .leading, spacing: 24) {
                    // Event Name Field
                    VStack(alignment: .leading, spacing: 10) {
                        Text("EVENT NAME")
                            .font(.system(size: 10, weight: .bold, design: .rounded))
                            .foregroundColor(.white.opacity(0.3))
                            .tracking(1.5)
                            .padding(.leading, 4)

                        TextField("e.g. Figma Config 2026", text: $eventName)
                            .font(.system(size: 16, weight: .semibold, design: .rounded))
                            .foregroundColor(.white)
                            .padding(20)
                            .background(
                                RoundedRectangle(cornerRadius: 18, style: .continuous)
                                    .fill(Color.white.opacity(0.06))
                            )
                    }

                    // Folder / Tag Field
                    VStack(alignment: .leading, spacing: 10) {
                        Text("FOLDER / TAG")
                            .font(.system(size: 10, weight: .bold, design: .rounded))
                            .foregroundColor(.white.opacity(0.3))
                            .tracking(1.5)
                            .padding(.leading, 4)

                        TextField("e.g. Design Leads", text: $folderName)
                            .font(.system(size: 16, weight: .semibold, design: .rounded))
                            .foregroundColor(.white)
                            .padding(20)
                            .background(
                                RoundedRectangle(cornerRadius: 18, style: .continuous)
                                    .fill(Color.white.opacity(0.06))
                            )
                    }
                }
                .padding(.horizontal, 8)

                Spacer()

                // Activate Session Button
                Button {
                    eventManager.goLive(event: eventName, folder: folderName)
                    store.createFolder(name: folderName)
                    UIImpactFeedbackGenerator(style: .heavy).impactOccurred()
                    dismiss()
                } label: {
                    Text("ACTIVATE SESSION")
                        .font(.system(size: 14, weight: .black, design: .rounded))
                        .tracking(1)
                        .foregroundColor(.black)
                        .frame(maxWidth: .infinity)
                        .frame(height: 64)
                        .background(
                            RoundedRectangle(cornerRadius: 22, style: .continuous)
                                .fill(Color.softRose)
                        )
                }
                .disabled(eventName.isEmpty || folderName.isEmpty)
                .opacity(eventName.isEmpty || folderName.isEmpty ? 0.4 : 1.0)
                .padding(.bottom, 20)
            }
            .padding(24)
        }
        .presentationDetents([.height(600)])
        .presentationDragIndicator(.visible)
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

