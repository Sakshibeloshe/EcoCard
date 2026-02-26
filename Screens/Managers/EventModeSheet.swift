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

    private var activeCode: String {
        role == .create ? eventManager.eventCode : joinCode.uppercased()
    }

    private var selectedCard: CardModel? {
        store.myCards.first(where: { $0.id == selectedCardID })
    }

    private var canActivate: Bool {
        !eventName.isEmpty && !activeCode.isEmpty && selectedCard != nil
    }

    var body: some View {
        ZStack {
            Color.obsidianBlack.ignoresSafeArea()

            ScrollView(showsIndicators: false) {
                VStack(spacing: 28) {

                    // MARK: Header
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
                        Text("Event Mode")
                            .font(.system(size: 28, weight: .bold, design: .rounded))
                            .foregroundColor(.white)

                        Text("GROUP CARD EXCHANGE")
                            .font(.system(size: 12, weight: .bold, design: .rounded))
                            .foregroundColor(.white.opacity(0.3))
                            .tracking(2)
                    }

                    // MARK: Role Picker
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
                                    .background(
                                        Capsule().fill(role == r ? Color.softRose : Color.clear)
                                    )
                            }
                        }
                    }
                    .padding(4)
                    .background(Color.white.opacity(0.06))
                    .clipShape(Capsule())
                    .padding(.horizontal, 8)

                    // MARK: Event Code
                    VStack(alignment: .leading, spacing: 10) {
                        Text("EVENT CODE")
                            .font(.system(size: 10, weight: .bold, design: .rounded))
                            .foregroundColor(.white.opacity(0.3))
                            .tracking(1.5)
                            .padding(.leading, 4)

                        if role == .create {
                            // Show generated code
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
                            .background(
                                RoundedRectangle(cornerRadius: 18, style: .continuous)
                                    .fill(Color.white.opacity(0.06))
                            )

                            Text("Share this code with attendees")
                                .font(.system(size: 12, weight: .medium))
                                .foregroundColor(.white.opacity(0.3))
                                .padding(.leading, 4)
                        } else {
                            // Enter code manually
                            TextField("Enter 6-digit code", text: $joinCode)
                                .font(.system(size: 22, weight: .heavy, design: .monospaced))
                                .foregroundColor(.white)
                                .tracking(4)
                                .multilineTextAlignment(.center)
                                .textInputAutocapitalization(.characters)
                                .autocorrectionDisabled()
                                .padding(20)
                                .background(
                                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                                        .fill(Color.white.opacity(0.06))
                                )
                                .onChange(of: joinCode) { newValue in
                                    // Limit to 6 characters
                                    if newValue.count > 6 {
                                        joinCode = String(newValue.prefix(6))
                                    }
                                }
                        }
                    }
                    .padding(.horizontal, 8)

                    // MARK: Event Name
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
                    .padding(.horizontal, 8)

                    // MARK: Card Selector
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
                                .background(
                                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                                        .fill(Color.white.opacity(0.06))
                                )
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

                    Spacer(minLength: 20)

                    // MARK: Activate Button
                    Button {
                        guard let card = selectedCard else { return }
                        let code = activeCode
                        let folder = eventName // use event name as folder

                        eventManager.goLive(event: eventName, folder: folder, code: code, card: card)
                        store.createFolder(name: folder)
                        eventPeerManager.start(eventCode: code, card: card)

                        UIImpactFeedbackGenerator(style: .heavy).impactOccurred()
                        dismiss()
                    } label: {
                        Text(role == .create ? "START EVENT" : "JOIN EVENT")
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
                    .disabled(!canActivate)
                    .opacity(canActivate ? 1.0 : 0.4)
                    .padding(.bottom, 20)
                }
                .padding(24)
            }
        }
        .presentationDetents([.large])
        .presentationDragIndicator(.visible)
        .onAppear {
            if role == .create && eventManager.eventCode.isEmpty {
                eventManager.generateEventCode()
            }
            // Pre-select first card if available
            if selectedCardID == nil, let first = store.myCards.first {
                selectedCardID = first.id
            }
        }
    }

    // MARK: - Card Tile

    private func cardTile(_ card: CardModel) -> some View {
        let isSelected = selectedCardID == card.id
        return VStack(spacing: 8) {
            ZStack {
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .fill(card.uiColor.opacity(0.2))
                    .frame(width: 100, height: 60)

                Text(String(card.fullName.prefix(2)).uppercased())
                    .font(.system(size: 20, weight: .bold, design: .rounded))
                    .foregroundColor(card.uiColor)
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
}
