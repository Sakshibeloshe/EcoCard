import SwiftUI

struct TouchModeView: View {
    @Environment(\.dismiss) private var dismiss
    let card: CardModel

    @StateObject private var transfer = PeerTransferManager()
    @State private var glowPulse = false
    @State private var cardOffset: CGFloat = 0
    @State private var showSuccess = false
    @State private var iconPulse = false

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()

            VStack(spacing: 0) {

                // Top bar
                HStack {
                    Button("Cancel") { dismiss() }
                        .foregroundColor(.white.opacity(0.5))
                        .font(.system(size: 16, weight: .medium))
                    Spacer()
                    Text("TOUCH MODE")
                        .font(.system(size: 12, weight: .black))
                        .foregroundColor(.white.opacity(0.35))
                        .tracking(2)
                    Spacer()
                    // invisible balance
                    Text("Cancel").opacity(0)
                }
                .padding(.horizontal, 24)
                .padding(.top, 20)

                Spacer()

                // Card with glow
                ZStack {
                    // Glow rings
                    ForEach(0..<4) { i in
                        RoundedRectangle(cornerRadius: 28, style: .continuous)
                            .stroke(card.uiColor.opacity(glowPulse ? 0 : 0.35), lineWidth: 2)
                            .frame(width: 300 + CGFloat(i * 22), height: 180 + CGFloat(i * 14))
                            .scaleEffect(glowPulse ? 1.18 : 1.0)
                            .opacity(glowPulse ? 0 : Double(4 - i) * 0.12)
                            .animation(
                                Animation.easeInOut(duration: 1.6)
                                    .repeatForever(autoreverses: true)
                                    .delay(Double(i) * 0.25),
                                value: glowPulse
                            )
                    }

                    CardFrontView(card: card)
                        .frame(width: 300)
                        .offset(y: cardOffset)
                        .shadow(color: card.uiColor.opacity(0.4), radius: 30, y: 10)
                }
                .padding(.vertical, 32)

                // Status area
                VStack(spacing: 16) {
                    statusIcon
                    statusText
                        .multilineTextAlignment(.center)
                }
                .frame(height: 100)
                .animation(.easeInOut(duration: 0.3), value: transfer.state)

                Spacer()

                // Retry if failed
                if case .failed = transfer.state {
                    Button("Retry") {
                        transfer.startSenderMode()
                    }
                    .font(.system(size: 16, weight: .bold, design: .rounded))
                    .foregroundColor(.black)
                    .padding(.horizontal, 40)
                    .padding(.vertical, 14)
                    .background(Color.white)
                    .clipShape(Capsule())
                    .padding(.bottom, 40)
                }
            }
        }
        .onAppear {
            glowPulse = true
            transfer.startSenderMode()
        }
        .onChange(of: transfer.state) { newState in
            if case .connected = newState {
                // Auto-send as soon as peer connects
                withAnimation(.spring(response: 0.5, dampingFraction: 0.6)) {
                    cardOffset = -8
                }
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                    transfer.sendCard(card.toPayload())
                }
            }
            if newState == .sent {
                UINotificationFeedbackGenerator().notificationOccurred(.success)
                withAnimation(.spring(response: 0.6, dampingFraction: 0.5)) {
                    cardOffset = -60
                    showSuccess = true
                }
                DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                    dismiss()
                }
            }
        }
        .onDisappear {
            transfer.stopSenderMode()
        }
    }

    // MARK: - Sub-views

    @ViewBuilder
    private var statusIcon: some View {
        switch transfer.state {
        case .idle, .advertising:
            Image(systemName: "wave.3.right")
                .font(.system(size: 34, weight: .semibold))
                .foregroundColor(.white.opacity(0.7))
        case .browsing:
            Image(systemName: "antenna.radiowaves.left.and.right")
                .font(.system(size: 34))
                .foregroundColor(.skyBlue)
        case .connecting:
            ProgressView()
                .tint(.white)
                .scaleEffect(1.4)
        case .connected:
            Image(systemName: "bolt.horizontal.fill")
                .font(.system(size: 34))
                .foregroundColor(.freshLime)
        case .sending:
            Image(systemName: "arrow.up.circle.fill")
                .font(.system(size: 34))
                .foregroundColor(.freshLime)
                .opacity(iconPulse ? 0.4 : 1.0)
                .animation(.easeInOut(duration: 0.6).repeatForever(autoreverses: true), value: iconPulse)
                .onAppear { iconPulse = true }
                .onDisappear { iconPulse = false }
        case .sent:
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 34))
                .foregroundColor(.freshLime)
        case .receiving, .received:
            EmptyView()
        case .failed:
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.system(size: 34))
                .foregroundColor(.softRose)
        }
    }

    @ViewBuilder
    private var statusText: some View {
        switch transfer.state {
        case .idle:
            label("Starting…", sub: nil)
        case .advertising:
            label("Ready to Tap", sub: "Hold top edges together")
        case .browsing:
            label("Searching…", sub: nil)
        case .connecting(let name):
            label("Connecting…", sub: name)
        case .connected(let name):
            label("Connected!", sub: name)
        case .sending:
            label("Sending card…", sub: nil)
        case .sent:
            label("✓ Card Sent!", sub: "The card is now in their Inbox")
        case .receiving, .received:
            EmptyView()
        case .failed(let msg):
            label("Failed", sub: msg)
        }
    }

    private func label(_ title: String, sub: String?) -> some View {
        VStack(spacing: 6) {
            Text(title)
                .font(.system(size: 22, weight: .bold, design: .rounded))
                .foregroundColor(.white)
            if let sub {
                Text(sub)
                    .font(.system(size: 13, weight: .medium, design: .rounded))
                    .foregroundColor(.white.opacity(0.4))
            }
        }
    }
}
