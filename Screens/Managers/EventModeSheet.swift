import SwiftUI

struct EventModeSheet: View {
    @EnvironmentObject var eventManager: EventModeManager
    @EnvironmentObject var eventPeerManager: EventModePeerManager
    @EnvironmentObject var store: AppStore
    @Environment(\.dismiss) var dismiss

    @State private var eventName: String = ""
    @State private var folderName: String = ""
    @State private var joinCode: String = ""
    @State private var mode: SheetMode = .selection
    @State private var persistedCardIDs: Set<UUID> = []

    enum SheetMode { case selection, create, join, active }

    var body: some View {
        ZStack {
            Color.obsidianBlack.ignoresSafeArea()

            VStack(spacing: 24) {
                headerArea

                if eventPeerManager.isActive {
                    activeSessionView
                } else {
                    switch mode {
                    case .selection: selectionView
                    case .create:    createEventView
                    case .join:      joinEventView
                    case .active:    activeSessionView
                    }
                }
            }
            .padding(24)
        }
        .onAppear {
            if eventPeerManager.isActive {
                mode = .active
            }
        }
        .onChange(of: eventPeerManager.receivedCards) { _, newValue in
            // Persist any newly-seen cards into the inbox, de-duping by ID.
            for card in newValue where !persistedCardIDs.contains(card.id) {
                store.saveInboxCardIfNew(card)
                persistedCardIDs.insert(card.id)
            }
        }
    }

    // MARK: - Subviews

    private var headerArea: some View {
        VStack(spacing: 12) {
            ZStack {
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .fill(Color.softRose)
                    .frame(width: 64, height: 64)
                
                Image(systemName: "bolt.fill")
                    .font(.system(size: 32, weight: .bold))
                    .foregroundColor(.black)
            }
            .padding(.top, 20)

            VStack(spacing: 4) {
                Text(eventPeerManager.isActive ? "Event Live" : "Event Mode")
                    .font(.system(size: 28, weight: .bold, design: .rounded))
                    .foregroundColor(.white)
                
                Text(eventPeerManager.isActive ? "AUTO-EXCHANGING CARDS" : "NETWORKING AT SCALE")
                    .font(.system(size: 10, weight: .bold, design: .rounded))
                    .foregroundColor(.white.opacity(0.3))
                    .tracking(2)
            }
        }
    }

    private var selectionView: some View {
        VStack(spacing: 16) {
            Spacer()
            
            actionButton(title: "CREATE NEW SESSION", icon: "plus.circle.fill", color: .softRose) {
                withAnimation { mode = .create }
            }

            actionButton(title: "JOIN EXISTING SESSION", icon: "person.2.fill", color: .white.opacity(0.1), textColor: .white) {
                withAnimation { mode = .join }
            }
            
            Spacer()
            
            Text("In Event Mode, everyone in the room automatically receives your card and you receive theirs.")
                .font(.system(size: 12, weight: .medium))
                .foregroundColor(.white.opacity(0.4))
                .multilineTextAlignment(.center)
                .padding(.horizontal, 20)
        }
    }

    private var createEventView: some View {
        VStack(spacing: 24) {
            VStack(alignment: .leading, spacing: 10) {
                fieldLabel("EVENT NAME")
                TextField("e.g. Apple Event 2026", text: $eventName)
                    .customField()
            }

            VStack(alignment: .leading, spacing: 10) {
                fieldLabel("FOLDER / TAG")
                TextField("e.g. Devs", text: $folderName)
                    .customField()
            }

            Spacer()

            actionButton(title: "GENERATE CODE & START", icon: "bolt.fill", color: .softRose) {
                startSession(isHost: true)
            }
            .disabled(eventName.isEmpty || folderName.isEmpty)
            .opacity(eventName.isEmpty || folderName.isEmpty ? 0.4 : 1.0)
            
            Button("Back") { withAnimation { mode = .selection } }
                .foregroundColor(.white.opacity(0.5))
                .font(.system(size: 14, weight: .bold))
        }
    }

    private var joinEventView: some View {
        VStack(spacing: 24) {
            VStack(alignment: .leading, spacing: 10) {
                fieldLabel("ENTER EVENT CODE")
                TextField("6-character code", text: $joinCode)
                    .font(.system(size: 32, weight: .black, design: .monospaced))
                    .multilineTextAlignment(.center)
                    .textCase(.uppercase)
                    .customField()
                    .onChange(of: joinCode) { _, newValue in
                        if newValue.count > 6 {
                            joinCode = String(newValue.prefix(6))
                        }
                    }
            }

            Spacer()

            actionButton(title: "JOIN SESSION", icon: "person.2.fill", color: .skyBlue) {
                startSession(isHost: false)
            }
            .disabled(joinCode.count < 4)
            .opacity(joinCode.count < 4 ? 0.4 : 1.0)

            Button("Back") { withAnimation { mode = .selection } }
                .foregroundColor(.white.opacity(0.5))
                .font(.system(size: 14, weight: .bold))
        }
    }

    private var activeSessionView: some View {
        VStack(spacing: 32) {
            VStack(spacing: 12) {
                Text(eventManager.eventName.isEmpty ? "Joined Session" : eventManager.eventName)
                    .font(.system(size: 20, weight: .bold, design: .rounded))
                    .foregroundColor(.white)
                
                Text(eventPeerManager.eventCode)
                    .font(.system(size: 48, weight: .black, design: .monospaced))
                    .foregroundColor(.softRose)
                    .padding(.horizontal, 24)
                    .padding(.vertical, 8)
                    .background(Color.white.opacity(0.05))
                    .cornerRadius(12)
            }

            HStack(spacing: 40) {
                statusStat(value: "\(eventPeerManager.connectedPeerCount)", label: "PEERS")
                statusStat(value: "\(eventPeerManager.receivedCards.count)", label: "CARDS")
            }
            .padding(.vertical, 20)

            VStack(spacing: 12) {
                ProgressView()
                    .tint(.softRose)
                Text(eventPeerManager.statusLabel)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.white.opacity(0.6))
            }

            Spacer()

            actionButton(title: "END SESSION", icon: "xmark.circle.fill", color: .red.opacity(0.8)) {
                eventPeerManager.stopSession()
                eventManager.stop()
                dismiss()
            }
        }
    }

    // MARK: - Logic

    private func startSession(isHost: Bool) {
        // Generate a random code if hosting
        let code = isHost ? generateRandomCode() : joinCode.uppercased()
        
        // Use the first card from myStack as our business card
        guard let myCard = store.myCards.first else {
            // Handle no cards case
            return
        }

        if isHost {
            eventManager.goLive(event: eventName, folder: folderName)
            store.createFolder(name: folderName)
        }
        
        eventPeerManager.startSession(eventCode: code, myCard: myCard)
        UIImpactFeedbackGenerator(style: .heavy).impactOccurred()
        withAnimation { mode = .active }
    }

    private func generateRandomCode() -> String {
        let letters = "ABCDEFGHJKLMNPQRSTUVWXYZ23456789"
        return String((0..<6).map { _ in letters.randomElement()! })
    }

    // MARK: - Helpers

    private func fieldLabel(_ text: String) -> some View {
        Text(text)
            .font(.system(size: 10, weight: .bold, design: .rounded))
            .foregroundColor(.white.opacity(0.3))
            .tracking(1.5)
            .padding(.leading, 4)
    }

    private func actionButton(title: String, icon: String, color: Color, textColor: Color = .black, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: 12) {
                Image(systemName: icon)
                Text(title)
            }
            .font(.system(size: 14, weight: .black, design: .rounded))
            .tracking(1)
            .foregroundColor(textColor)
            .frame(maxWidth: .infinity)
            .frame(height: 64)
            .background(
                RoundedRectangle(cornerRadius: 22, style: .continuous)
                    .fill(color)
            )
        }
    }

    private func statusStat(value: String, label: String) -> some View {
        VStack(spacing: 4) {
            Text(value)
                .font(.system(size: 24, weight: .black, design: .rounded))
                .foregroundColor(.white)
            Text(label)
                .font(.system(size: 10, weight: .bold))
                .foregroundColor(.white.opacity(0.3))
                .tracking(1)
        }
    }
}

extension View {
    func customField() -> some View {
        self.padding(20)
            .background(
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .fill(Color.white.opacity(0.06))
            )
            .foregroundColor(.white)
    }
}
