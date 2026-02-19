import SwiftUI

struct ReceiveModeView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var store: AppStore

    @StateObject private var transfer = PeerTransferManager()
    @State private var receivedCard: CardModel?
    @State private var showCardDetail = false
    @State private var waveOffset = false

    var body: some View {
        NavigationStack {
            ZStack {
                Color.black.ignoresSafeArea()

                VStack(spacing: 0) {

                    Spacer()

                    // Animation area
                    ZStack {
                        // Radiating rings
                        ForEach(0..<4) { i in
                            Circle()
                                .stroke(Color.skyBlue.opacity(0.15), lineWidth: 1.5)
                                .frame(width: 80 + CGFloat(i * 55),
                                       height: 80 + CGFloat(i * 55))
                                .scaleEffect(waveOffset ? 1.15 : 1.0)
                                .opacity(waveOffset ? 0 : 1)
                                .animation(
                                    Animation.easeOut(duration: 2.0)
                                        .repeatForever(autoreverses: false)
                                        .delay(Double(i) * 0.5),
                                    value: waveOffset
                                )
                        }

                        // Center icon
                        ZStack {
                            Circle()
                                .fill(Color.skyBlue.opacity(0.12))
                                .frame(width: 80, height: 80)

                            Image(systemName: "antenna.radiowaves.left.and.right")
                                .font(.system(size: 32, weight: .semibold))
                                .foregroundColor(.skyBlue)
                        }
                    }
                    .frame(height: 280)

                    // Status
                    VStack(spacing: 12) {
                        statusTitle
                            .font(.system(size: 26, weight: .bold, design: .rounded))
                            .foregroundColor(.white)
                            .multilineTextAlignment(.center)

                        statusSub
                            .font(.system(size: 14, weight: .medium, design: .rounded))
                            .foregroundColor(.white.opacity(0.4))
                            .multilineTextAlignment(.center)
                    }
                    .animation(.easeInOut(duration: 0.3), value: transfer.state)
                    .padding(.top, 36)

                    // Received card preview
                    if let card = receivedCard {
                        VStack(spacing: 16) {
                            CardFrontView(card: card)
                                .frame(width: 300)
                                .padding(.top, 32)
                                .transition(.move(edge: .bottom).combined(with: .opacity))

                            Button("View in Inbox") {
                                showCardDetail = true
                            }
                            .font(.system(size: 16, weight: .bold, design: .rounded))
                            .foregroundColor(.black)
                            .padding(.horizontal, 40)
                            .padding(.vertical, 14)
                            .background(Color.freshLime)
                            .clipShape(Capsule())
                            .transition(.opacity.combined(with: .scale))
                        }
                        .animation(.spring(response: 0.5, dampingFraction: 0.75), value: receivedCard != nil)
                    }

                    Spacer()
                }
                .padding(.horizontal, 24)
            }
            .navigationTitle("")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Close") { dismiss() }
                        .foregroundColor(.white.opacity(0.5))
                        .font(.system(size: 16, weight: .medium))
                }
                ToolbarItem(placement: .principal) {
                    Text("RECEIVER MODE")
                        .font(.system(size: 12, weight: .black))
                        .foregroundColor(.white.opacity(0.35))
                        .tracking(2)
                }
            }
            .navigationDestination(isPresented: $showCardDetail) {
                if let card = receivedCard {
                    CardDetailView(card: card)
                }
            }
        }
        .onAppear {
            waveOffset = true

            transfer.onCardReceived = { payload in
                store.importCard(payload)
                // Rebuild CardModel from payload to show locally
                let card = CardModel(
                    id: UUID(uuidString: payload.id) ?? UUID(),
                    type: CardType(rawValue: payload.type) ?? .personal,
                    theme: CardTheme(rawValue: payload.theme) ?? .sky,
                    fullName: payload.displayName,
                    title: payload.title,
                    company: payload.company,
                    bio: payload.bio,
                    email: payload.email,
                    website: payload.website,
                    phone: payload.phone,
                    pronouns: payload.pronouns,
                    instagram: payload.instagram,
                    linkedIn: payload.linkedIn,
                    github: payload.github,
                    portfolio: payload.portfolio,
                    isReceived: true
                )
                withAnimation {
                    receivedCard = card
                }
                // Auto-open detail after brief pause
                Task {
                    try? await Task.sleep(nanoseconds: 1_000_000_000)
                    showCardDetail = true
                }
            }
            Task {
                try? await Task.sleep(nanoseconds: 300_000_000)
                transfer.startReceiverMode()
            }
        }
        .onDisappear {
            transfer.stopReceiverMode()
        }
    }

    // MARK: - Status sub-views

    @ViewBuilder
    private var statusTitle: some View {
        switch transfer.state {
        case .idle:             Text("Starting…")
        case .browsing:         Text("Searching for cards…")
        case .connecting(let n): Text("Found \(n)")
        case .connected(let n): Text("Connected to \(n)")
        case .receiving:        Text("Receiving card…")
        case .received:         Text("Card Received! 🎉")
        case .failed:           Text("Connection Failed")
        default:                Text("Receiver Mode")
        }
    }

    @ViewBuilder
    private var statusSub: some View {
        switch transfer.state {
        case .browsing:
            Text("Ask them to open a card and tap BEAM")
        case .connecting:
            Text("Connecting…")
        case .connected:
            Text("Waiting for card…")
        case .failed(let msg):
            Text(msg)
        default:
            Text("Make sure Wi-Fi and Bluetooth are on")
        }
    }
}
