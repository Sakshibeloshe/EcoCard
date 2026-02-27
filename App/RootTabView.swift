import SwiftUI

struct RootTabView: View {
    @EnvironmentObject var store: AppStore

    @State private var showScanner: Bool = false
    @State private var scannedCard: CardModel? = nil
    @State private var showScanSuccess: Bool = false


    var body: some View {
        ZStack {
            Color.obsidianBlack.ignoresSafeArea()

            ZStack {
                if store.activeTab == .myCards {
                    NavigationStack { MyCardsView() }
                        .transition(.asymmetric(
                            insertion: .opacity.combined(with: .move(edge: .bottom)),
                            removal: .opacity
                        ))
                } else if store.activeTab == .add {
                    NavigationStack { AddCardView() }
                        .transition(.asymmetric(
                            insertion: .opacity.combined(with: .move(edge: .bottom)),
                            removal: .opacity
                        ))
                } else if store.activeTab == .inbox {
                    InboxView()
                        .transition(.asymmetric(
                            insertion: .opacity.combined(with: .move(edge: .bottom)),
                            removal: .opacity
                        ))
                }
            }

            .animation(.easeInOut(duration: 0.22), value: store.activeTab)

            FloatingTabBar(selectedTab: $store.activeTab, showScanner: $showScanner)

        }
        .sheet(isPresented: $showScanner) {
            QRScanSheet(
                onCardScanned: { card in
                    store.saveInboxCard(card)
                    scannedCard = card
                    showScanner = false
                    showScanSuccess = true
                    UINotificationFeedbackGenerator().notificationOccurred(.success)
                }
            )
        }
        .alert("Card Received!", isPresented: $showScanSuccess) {
            Button("View In Inbox") {
                store.activeTab = .inbox
            }
            Button("OK", role: .cancel) {}
        } message: {
            if let card = scannedCard {
                Text("Saved \(card.fullName)'s card to your inbox.")
            }
        }
    }
}

// MARK: - QR Scan Sheet

struct QRScanSheet: View {
    @Environment(\.dismiss) var dismiss
    var onCardScanned: (CardModel) -> Void

    @State private var hasScanned = false
    @State private var errorMessage: String? = nil

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()

            VStack(spacing: 24) {
                // Top bar
                HStack {
                    Button {
                        dismiss()
                    } label: {
                        Text("Cancel")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(.white.opacity(0.6))
                    }
                    Spacer()
                    Text("SCAN QR CODE")
                        .font(.system(size: 12, weight: .black, design: .rounded))
                        .tracking(1.5)
                        .foregroundColor(.white.opacity(0.5))
                    Spacer()
                    // Balance spacer
                    Text("Cancel").opacity(0)
                        .font(.system(size: 16, weight: .medium))
                }
                .padding(.horizontal, 20)
                .padding(.top, 20)

                Spacer()

                // Scanner
                ZStack {
                    QRCodeScannerView { scannedString in
                        guard !hasScanned else { return }

                        if let card = QRCodeGenerator.decode(scannedString) {
                            hasScanned = true
                            onCardScanned(card)
                        } else {
                            errorMessage = "Not a valid EcoCard QR code"
                            Task {
                                try? await Task.sleep(nanoseconds: 2_000_000_000)
                                await MainActor.run { errorMessage = nil }
                            }
                        }
                    }
                    .frame(width: 280, height: 280)
                    .clipShape(RoundedRectangle(cornerRadius: 24))

                    // Corner frame overlay
                    RoundedRectangle(cornerRadius: 24)
                        .stroke(Color.skyBlue.opacity(0.5), lineWidth: 2)
                        .frame(width: 280, height: 280)

                    // Scanning line animation
                    ScanLineView()
                        .frame(width: 260, height: 280)
                        .clipShape(RoundedRectangle(cornerRadius: 20))
                }

                VStack(spacing: 8) {
                    Text("Point at a QR Code")
                        .font(.system(size: 22, weight: .bold, design: .rounded))
                        .foregroundColor(.white)

                    Text("SCAN ANOTHER PERSON'S CARD QR")
                        .font(.system(size: 10, weight: .black))
                        .foregroundColor(.white.opacity(0.3))
                        .tracking(1.4)

                    if let error = errorMessage {
                        Text(error)
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundColor(.red.opacity(0.8))
                            .padding(.top, 4)
                            .transition(.opacity)
                    }
                }

                Spacer()
            }
        }
        .presentationDetents([.large])
        .presentationDragIndicator(.visible)
    }
}

// MARK: - Scanning Line Animation

struct ScanLineView: View {
    @State private var offset: CGFloat = -120

    var body: some View {
        Rectangle()
            .fill(
                LinearGradient(
                    colors: [.skyBlue.opacity(0), .skyBlue.opacity(0.5), .skyBlue.opacity(0)],
                    startPoint: .leading,
                    endPoint: .trailing
                )
            )
            .frame(height: 2)
            .offset(y: offset)
            .onAppear {
                withAnimation(.easeInOut(duration: 2.0).repeatForever(autoreverses: true)) {
                    offset = 120
                }
            }
    }
}

enum Tab {
    case myCards, add, inbox
}
