
import SwiftUI

struct ShareCardView: View {
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var peerManager: PeerManager
    @EnvironmentObject var store: AppStore

    let card: CardModel

    @State private var shareMode: ShareMode = .touch
    @State private var isAnimating = false
    @State private var hasSentCard = false

    // QR mode state
    @State private var qrRole: QRRole = .sender          // sender shows QR; receiver scans
    @State private var qrImage: UIImage? = nil
    @State private var scannedCard: CardModel? = nil
    @State private var showScannedSuccess = false

    enum ShareMode { case touch, qr }
    enum QRRole    { case sender, receiver }

    // MARK: - Body

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()

            VStack {
                topBar
                Spacer()

                TabView(selection: $shareMode) {
                    touchModeView.tag(ShareMode.touch)
                    qrModeView.tag(ShareMode.qr)
                }
                .tabViewStyle(.page(indexDisplayMode: .never))
                .frame(height: 540)

                Spacer()
            }
        }
        .onChange(of: peerManager.isConnected) { connected in
            if connected && !hasSentCard && shareMode == .touch {
                hasSentCard = true
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
                    peerManager.sendCard(card)
                }
            }
        }
        .onChange(of: shareMode) { mode in
            if mode == .touch {
                hasSentCard = false
                peerManager.startBrowsing()
            } else {
                peerManager.stopBrowsing()
                generateQRIfNeeded()
            }
        }
        .onAppear {
            generateQRIfNeeded()
        }
    }

    // MARK: - Top Bar

    private var topBar: some View {
        HStack {
            Button("Cancel") {
                peerManager.stopBrowsing()
                dismiss()
            }
            .foregroundColor(.white.opacity(0.5))
            .font(.system(size: 16, weight: .medium))

            Spacer()

            HStack(spacing: 0) {
                toggleButton(title: "TOUCH", mode: .touch)
                toggleButton(title: "QR",    mode: .qr)
            }
            .padding(4)
            .background(Color.white.opacity(0.1))
            .clipShape(Capsule())

            Spacer()

            // Share button — exports QR image via system sheet
            Button {
                if shareMode == .qr, let img = qrImage {
                    let av = UIActivityViewController(
                        activityItems: [img],
                        applicationActivities: nil
                    )
                    if let scene = UIApplication.shared.connectedScenes
                        .compactMap({ $0 as? UIWindowScene }).first,
                       let root = scene.windows.first?.rootViewController {
                        root.present(av, animated: true)
                    }
                }
            } label: {
                Image(systemName: "square.and.arrow.up")
                    .font(.system(size: 18, weight: .medium))
                    .foregroundColor(shareMode == .qr ? .white.opacity(0.8) : .white.opacity(0.3))
            }
        }
        .padding(.horizontal, 20)
        .padding(.top, 20)
    }

    // MARK: - Toggle Button

    private func toggleButton(title: String, mode: ShareMode) -> some View {
        Button {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                shareMode = mode
            }
            UIImpactFeedbackGenerator(style: .light).impactOccurred()
        } label: {
            Text(title)
                .font(.system(size: 13, weight: .bold))
                .foregroundColor(shareMode == mode ? .black : .white)
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(Capsule().fill(shareMode == mode ? Color.white : Color.clear))
        }
    }

    // MARK: - Touch Mode View

    private var touchModeView: some View {
        VStack(spacing: 32) {
            CardView(card: card)
                .frame(width: 280)
                .scaleEffect(0.8)

            ZStack {
                ForEach(0..<3) { i in
                    Circle()
                        .stroke(rippleColor.opacity(0.25), lineWidth: 1)
                        .frame(width: 100, height: 100)
                        .scaleEffect(isAnimating ? 3 : 1)
                        .opacity(isAnimating ? 0 : 1)
                        .animation(
                            Animation.easeOut(duration: 2.5)
                                .repeatForever(autoreverses: false)
                                .delay(Double(i) * 0.8),
                            value: isAnimating
                        )
                }

                Image(systemName: peerManager.isConnected ? "checkmark.circle.fill" : "wave.3.right")
                    .font(.system(size: 40))
                    .foregroundColor(rippleColor)
                    .offset(x: peerManager.isConnected ? 0 : -4)
                    .animation(.spring(response: 0.4, dampingFraction: 0.6), value: peerManager.isConnected)
            }
            .onAppear {
                isAnimating = true
                peerManager.startBrowsing()
                hasSentCard = false
            }
            .onDisappear {
                peerManager.stopBrowsing()
            }

            VStack(spacing: 6) {
                Text(statusTitle)
                    .font(.system(size: 22, weight: .bold, design: .rounded))
                    .foregroundColor(rippleColor)

                Text(statusSubtitle)
                    .font(.system(size: 12, weight: .bold))
                    .foregroundColor(rippleColor.opacity(0.5))
                    .tracking(1.4)
                    .multilineTextAlignment(.center)

                // QR fallback hint — only shown when not yet connected
                if !peerManager.isConnected && !hasSentCard {
                    Button {
                        withAnimation { shareMode = .qr }
                    } label: {
                        Text("No connection? Use QR instead →")
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(.skyBlue.opacity(0.7))
                            .underline()
                    }
                    .padding(.top, 4)
                }
            }
        }
    }

    // MARK: - QR Mode View

    private var qrModeView: some View {
        VStack(spacing: 24) {

            // Role switcher
            HStack(spacing: 0) {
                roleButton(title: "Show QR",  role: .sender)
                roleButton(title: "Scan QR",  role: .receiver)
            }
            .padding(3)
            .background(Color.white.opacity(0.08))
            .clipShape(Capsule())

            if qrRole == .sender {
                senderQRView
            } else {
                receiverScanView
            }
        }
    }

    // MARK: Sender — shows the QR code

    private var senderQRView: some View {
        VStack(spacing: 20) {
            if let img = qrImage {
                Image(uiImage: img)
                    .interpolation(.none)        // keeps pixels crisp
                    .resizable()
                    .scaledToFit()
                    .frame(width: 220, height: 220)
                    .padding(20)
                    .background(Color.white)
                    .cornerRadius(20)
                    .shadow(color: .white.opacity(0.15), radius: 20)
                    .transition(.scale.combined(with: .opacity))
            } else {
                ProgressView()
                    .frame(width: 220, height: 220)
            }

            VStack(spacing: 4) {
                Text("Let them scan this")
                    .font(.system(size: 20, weight: .bold, design: .rounded))
                    .foregroundColor(.white)

                Text("POINT THEIR CAMERA AT YOUR SCREEN")
                    .font(.system(size: 10, weight: .black))
                    .foregroundColor(.white.opacity(0.35))
                    .tracking(1.4)
            }
        }
    }

    // MARK: Receiver — camera scanner

    private var receiverScanView: some View {
        VStack(spacing: 20) {
            ZStack {
                // Camera feed
                QRCodeScannerView { scanned in
                    if let decoded = QRCodeGenerator.decode(scanned) {
                        scannedCard = decoded
                        store.saveInboxCard(decoded)
                        withAnimation { showScannedSuccess = true }
                        UINotificationFeedbackGenerator().notificationOccurred(.success)
                    }
                }
                .frame(width: 240, height: 240)
                .clipShape(RoundedRectangle(cornerRadius: 20))

                // Corner frame overlay (decorative)
                RoundedRectangle(cornerRadius: 20)
                    .stroke(Color.skyBlue.opacity(0.6), lineWidth: 2)
                    .frame(width: 240, height: 240)

                if showScannedSuccess {
                    RoundedRectangle(cornerRadius: 20)
                        .fill(Color.black.opacity(0.75))
                        .frame(width: 240, height: 240)

                    VStack(spacing: 10) {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 50))
                            .foregroundColor(.green)
                        Text("Card Saved!")
                            .font(.system(size: 18, weight: .bold, design: .rounded))
                            .foregroundColor(.white)
                        if let name = scannedCard?.fullName {
                            Text(name)
                                .font(.system(size: 13, weight: .medium))
                                .foregroundColor(.white.opacity(0.7))
                        }
                    }
                    .transition(.scale.combined(with: .opacity))
                }
            }

            VStack(spacing: 4) {
                Text(showScannedSuccess ? "Card Received!" : "Scan Sender's QR")
                    .font(.system(size: 20, weight: .bold, design: .rounded))
                    .foregroundColor(showScannedSuccess ? .green : .white)
                    .animation(.easeInOut(duration: 0.25), value: showScannedSuccess)

                Text(showScannedSuccess
                     ? "SAVED TO YOUR INBOX"
                     : "AIM AT THE QR CODE ON THEIR SCREEN")
                    .font(.system(size: 10, weight: .black))
                    .foregroundColor(.white.opacity(0.35))
                    .tracking(1.4)
            }

            // Scan again button
            if showScannedSuccess {
                Button {
                    withAnimation { showScannedSuccess = false }
                    scannedCard = nil
                } label: {
                    Text("Scan another card")
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(.skyBlue.opacity(0.8))
                        .underline()
                }
            }
        }
    }

    // MARK: - Role toggle pill

    private func roleButton(title: String, role: QRRole) -> some View {
        Button {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                qrRole = role
            }
            UIImpactFeedbackGenerator(style: .light).impactOccurred()
        } label: {
            Text(title)
                .font(.system(size: 12, weight: .bold))
                .foregroundColor(qrRole == role ? .black : .white.opacity(0.6))
                .padding(.horizontal, 18)
                .padding(.vertical, 8)
                .background(Capsule().fill(qrRole == role ? Color.white : Color.clear))
        }
    }

    // MARK: - Helpers

    private func generateQRIfNeeded() {
        guard qrImage == nil else { return }
        DispatchQueue.global(qos: .userInitiated).async {
            let img = QRCodeGenerator.generate(from: card, size: 440)
            DispatchQueue.main.async { qrImage = img }
        }
    }

    private var statusTitle: String {
        if hasSentCard { return "Card Sent!" }
        if peerManager.isConnected { return "Connected — Sending…" }
        return "Searching…"
    }

    private var statusSubtitle: String {
        if hasSentCard { return "CARD DELIVERED SUCCESSFULLY" }
        if peerManager.isConnected { return "FOUND RECEIVER — TRANSFERRING" }
        return "HOLD DEVICES CLOSE TOGETHER"
    }

    private var rippleColor: Color {
        hasSentCard ? .green : (peerManager.isConnected ? Color.skyBlue : .white)
    }
}
