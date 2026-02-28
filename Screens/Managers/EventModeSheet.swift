import SwiftUI

struct EventModeSheet: View {
    @EnvironmentObject var eventManager: EventModeManager
    @EnvironmentObject var eventPeerManager: EventPeerManager
    @EnvironmentObject var store: AppStore
    @Environment(\.dismiss) var dismiss

    enum EventRole: String, CaseIterable {
        case create = "Create"
        case join   = "Join"
    }

    @State private var role: EventRole = .create
    @State private var eventName: String = ""
    @State private var folderName: String = ""
    @State private var joinCode: String = ""
    @State private var selectedCardID: UUID? = nil
    @State private var persistedCardIDs: Set<UUID> = []

    private var activeCode: String {
        role == .create ? eventManager.eventCode : joinCode.uppercased()
    }

    private var selectedCard: CardModel? {
        store.myCards.first(where: { $0.id == selectedCardID })
    }

    private var canActivate: Bool {
        let folderOK = !folderName.trimmingCharacters(in: .whitespaces).isEmpty
        if role == .create {
            return !eventName.isEmpty && !eventManager.eventCode.isEmpty && selectedCard != nil && folderOK
        } else {
            return joinCode.count >= 4 && selectedCard != nil && folderOK
        }
    }

    var body: some View {
        ZStack {
            Color.obsidianBlack.ignoresSafeArea()

            if eventPeerManager.isActive {
                activeSessionView
            } else {
                setupView
            }
        }
        .onAppear {
            if role == .create && eventManager.eventCode.isEmpty {
                eventManager.generateEventCode()
            }
            // Pre-select first card if available
            if selectedCardID == nil, let first = store.myCards.first {
                selectedCardID = first.id
            }
        }
        .onChange(of: eventPeerManager.receivedCards) { newValue in
            // Persist any newly-seen cards into the inbox, de-duping by ID.
            for card in newValue where !persistedCardIDs.contains(card.id) {
                store.saveInboxCardIfNew(card)
                persistedCardIDs.insert(card.id)
            }
        }
        .onAppear {
            eventPeerManager.onSessionEnded = {
                dismiss()
            }
        }
    }

    // MARK: - Setup View

    private var setupView: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 28) {
                setupHeader
                setupRolePicker
                setupCodeSection
                if role == .create { setupEventNameField }
                setupFolderNameField
                setupCardSelector
                Spacer(minLength: 20)
                setupActivateButton
            }
            .padding(24)
        }
    }

    private var setupHeader: some View {
        VStack(spacing: 8) {
            ZStack {
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .fill(Color.softRose)
                    .frame(width: 64, height: 64)
                Image(systemName: "bolt.fill")
                    .font(.system(size: 32, weight: .bold))
                    .foregroundColor(.black)
            }
            .padding(.top, 40)

            Text("Event Mode")
                .font(.system(size: 28, weight: .bold, design: .rounded))
                .foregroundColor(.white)
            Text("GROUP CARD EXCHANGE")
                .font(.system(size: 11, weight: .bold, design: .rounded))
                .foregroundColor(.white.opacity(0.3))
                .tracking(2)
        }
    }

    private var setupRolePicker: some View {
        HStack(spacing: 0) {
            ForEach(EventRole.allCases, id: \.self) { r in
                Button {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                        role = r
                        if r == .create && eventManager.eventCode.isEmpty {
                            eventManager.generateEventCode()
                        }
                    }
                } label: {
                    Text(r.rawValue.uppercased())
                        .font(.system(size: 12, weight: .bold))
                        .tracking(1)
                        .foregroundColor(role == r ? .black : .white.opacity(0.5))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .background(Capsule().fill(role == r ? Color.softRose : Color.clear))
                }
            }
        }
        .padding(4)
        .background(Color.white.opacity(0.06))
        .clipShape(Capsule())
        .padding(.horizontal, 8)
    }

    private var setupCodeSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("EVENT CODE")
                .font(.system(size: 10, weight: .bold, design: .rounded))
                .foregroundColor(.white.opacity(0.3))
                .tracking(1.5)
                .padding(.leading, 4)

            if role == .create {
                HStack {
                    Text(eventManager.eventCode)
                        .font(.system(size: 28, weight: .heavy, design: .monospaced))
                        .foregroundColor(.softRose)
                        .tracking(6)
                    Spacer()
                    Button {
                        eventManager.generateEventCode()
                        UIImpactFeedbackGenerator(style: .light).impactOccurred()
                    } label: {
                        Image(systemName: "arrow.clockwise")
                            .font(.system(size: 16, weight: .bold))
                            .foregroundColor(.white.opacity(0.5))
                    }
                }
                .padding(20)
                .background(RoundedRectangle(cornerRadius: 18, style: .continuous).fill(Color.white.opacity(0.06)))

                Text("Share this code with attendees")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(.white.opacity(0.3))
                    .padding(.leading, 4)
            } else {
                TextField("Enter 6-digit code", text: $joinCode)
                    .font(.system(size: 22, weight: .heavy, design: .monospaced))
                    .foregroundColor(.white)
                    .tracking(4)
                    .multilineTextAlignment(.center)
                    .textInputAutocapitalization(.characters)
                    .autocorrectionDisabled()
                    .padding(20)
                    .background(RoundedRectangle(cornerRadius: 18, style: .continuous).fill(Color.white.opacity(0.06)))
                    .onChange(of: joinCode) { newValue in
                        if newValue.count > 6 { joinCode = String(newValue.prefix(6)) }
                    }
            }
        }
        .padding(.horizontal, 8)
    }

    private var setupEventNameField: some View {
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
                .background(RoundedRectangle(cornerRadius: 18, style: .continuous).fill(Color.white.opacity(0.06)))
        }
        .padding(.horizontal, 8)
    }

    private var setupFolderNameField: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("SAVE TO FOLDER")
                .font(.system(size: 10, weight: .bold, design: .rounded))
                .foregroundColor(.white.opacity(0.3))
                .tracking(1.5)
                .padding(.leading, 4)
            HStack(spacing: 12) {
                Image(systemName: "folder.fill")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(.softRose.opacity(0.7))
                TextField(role == .create ? "e.g. Design Week" : "e.g. Config 2026", text: $folderName)
                    .font(.system(size: 16, weight: .semibold, design: .rounded))
                    .foregroundColor(.white)
                    .autocorrectionDisabled()
            }
            .padding(20)
            .background(RoundedRectangle(cornerRadius: 18, style: .continuous).fill(Color.white.opacity(0.06))
                .overlay(RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .stroke(folderName.isEmpty ? Color.clear : Color.softRose.opacity(0.3), lineWidth: 1)))
            Text("Received cards will be placed in this folder")
                .font(.system(size: 12, weight: .medium))
                .foregroundColor(.white.opacity(0.3))
                .padding(.leading, 4)
        }
        .padding(.horizontal, 8)
    }

    private var setupCardSelector: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("CARD TO SHARE")
                .font(.system(size: 10, weight: .bold, design: .rounded))
                .foregroundColor(.white.opacity(0.3))
                .tracking(1.5)
                .padding(.leading, 4)

            if store.myCards.isEmpty {
                Text("No cards yet — create one first!")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.white.opacity(0.4))
                    .padding(20)
                    .frame(maxWidth: .infinity)
                    .background(RoundedRectangle(cornerRadius: 18, style: .continuous).fill(Color.white.opacity(0.06)))
            } else {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 12) {
                        ForEach(store.myCards) { card in
                            Button {
                                withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                    selectedCardID = card.id
                                }
                                UIImpactFeedbackGenerator(style: .light).impactOccurred()
                            } label: {
                                cardTile(card)
                            }
                        }
                    }
                    .padding(.horizontal, 4)
                }
            }
        }
        .padding(.horizontal, 8)
    }

    private var setupActivateButton: some View {
        let label = role == .create ? "START EVENT" : "JOIN EVENT"
        return Button {
            guard let card = selectedCard else { return }
            let code = activeCode
            let folder = folderName.trimmingCharacters(in: .whitespaces)
            let isHost = (role == .create)
            let finalEventName = isHost ? eventName : (folder.isEmpty ? "Joined Session" : folder)
            eventManager.goLive(event: finalEventName, folder: folder, code: code, card: card, isHost: isHost)
            store.createFolder(name: folder)
            eventPeerManager.start(eventCode: code, card: card)
            UIImpactFeedbackGenerator(style: .heavy).impactOccurred()
        } label: {
            Text(label)
                .font(.system(size: 14, weight: .black, design: .rounded))
                .tracking(1)
                .foregroundColor(.black)
                .frame(maxWidth: .infinity)
                .frame(height: 64)
                .background(RoundedRectangle(cornerRadius: 22, style: .continuous).fill(Color.softRose))
        }
        .disabled(!canActivate)
        .opacity(canActivate ? 1.0 : 0.4)
        .padding(.bottom, 20)
    }

    // MARK: - Active Session View

    private var activeSessionView: some View {
        VStack(spacing: 32) {
            VStack(spacing: 12) {
                Text(eventManager.eventName.isEmpty ? "Active Session" : eventManager.eventName)
                    .font(.system(size: 24, weight: .bold, design: .rounded))
                    .foregroundColor(.white)
                
                Text(eventManager.eventCode)
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
            .padding(.vertical, 8)

            if !eventPeerManager.connectedPeers.isEmpty {
                VStack(alignment: .leading, spacing: 12) {
                    Text("CONNECTED PEERS")
                        .font(.system(size: 10, weight: .bold))
                        .foregroundColor(.white.opacity(0.3))
                        .tracking(1.5)
                        .padding(.leading, 8)

                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 10) {
                            ForEach(eventPeerManager.connectedPeers, id: \.self) { name in
                                Text(name)
                                    .font(.system(size: 11, weight: .bold))
                                    .foregroundColor(.black)
                                    .padding(.horizontal, 14)
                                    .padding(.vertical, 8)
                                    .background(Capsule().fill(Color.softRose.opacity(0.8)))
                            }
                        }
                    }
                }
                .padding(.horizontal, 8)
            }

            VStack(spacing: 16) {
                ProgressView()
                    .tint(.softRose)
                Text(eventPeerManager.statusLabel)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.white.opacity(0.6))
                    .multilineTextAlignment(.center)
            }

            Spacer()

            Button {
                if eventManager.isHost {
                    eventPeerManager.sendTerminationSignal()
                }
                eventPeerManager.stop()
                eventManager.stop()
                dismiss()
            } label: {
                HStack(spacing: 12) {
                    Image(systemName: "xmark.circle.fill")
                    Text("END SESSION")
                }
                .font(.system(size: 14, weight: .black, design: .rounded))
                .tracking(1)
                .foregroundColor(.black)
                .frame(maxWidth: .infinity)
                .frame(height: 64)
                .background(
                    RoundedRectangle(cornerRadius: 22, style: .continuous)
                        .fill(Color.red.opacity(0.8))
                )
            }
        }
        .padding(32)
    }

    // MARK: - Helpers

    private func cardTile(_ card: CardModel) -> some View {
        let isSelected = selectedCardID == card.id
        return VStack(spacing: 8) {
            ZStack {
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .fill(card.theme.color.opacity(0.2))
                    .frame(width: 100, height: 60)

                Text(String(card.fullName.prefix(2)).uppercased())
                    .font(.system(size: 20, weight: .bold, design: .rounded))
                    .foregroundColor(card.theme.color)
            }
            .overlay(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .stroke(isSelected ? Color.softRose : Color.white.opacity(0.1), lineWidth: isSelected ? 2 : 1)
            )

            Text(card.fullName)
                .font(.system(size: 11, weight: .semibold))
                .foregroundColor(isSelected ? .white : .white.opacity(0.5))
                .lineLimit(1)
                .frame(width: 100)
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
