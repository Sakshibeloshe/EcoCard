
import SwiftUI

struct TopNavBar: View {
    @EnvironmentObject var eventManager: EventModeManager
    @EnvironmentObject var peerManager: PeerManager
    @EnvironmentObject var eventPeerManager: EventPeerManager
    @State private var showSettings = false
    @State private var showEventSheet = false

    var body: some View {
        VStack(spacing: 0) {
            HStack(spacing: 8) {
                // Receiver Mode Button (Primary)
                Button {
                    eventManager.toggleReceiver()

                    // Start or stop advertising depending on new state
                    if eventManager.isReceiverActive {
                        peerManager.startHosting()
                    } else {
                        peerManager.stopHosting()
                    }

                    UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                } label: {
                    ReceiverModeButton(isLive: eventManager.isReceiverActive)
                }

                // Event Mode Button (Contextual)
                Button {
                    if eventManager.isLive {
                        eventManager.stop()
                        eventPeerManager.stop()
                    } else {
                        showEventSheet = true
                    }
                    UIImpactFeedbackGenerator(style: .light).impactOccurred()
                } label: {
                    EventModeButton(isLive: eventManager.isLive)
                }

                Spacer()

                // Settings Button (Utility)
                Button {
                    showSettings = true
                    UIImpactFeedbackGenerator(style: .light).impactOccurred()
                } label: {
                    Image(systemName: "gearshape.fill")
                        .font(.system(size: 16, weight: .bold))
                        .foregroundColor(.white.opacity(0.8))
                        .frame(width: 44, height: 44)
                        .background(
                            Circle()
                                .fill(Color.white.opacity(0.06))
                                .overlay(
                                    Circle()
                                        .stroke(Color.white.opacity(0.1), lineWidth: 1)
                                )
                        )
                }
            }
            .padding(.top, 4)
            .padding(.bottom, 12)

            // Status banner — event mode takes priority, then receiver mode
            if eventManager.isLive {
                eventStatusBanner
            } else if eventManager.isReceiverActive {
                receiverStatusBanner
            }
        }
        .sheet(isPresented: $showSettings) {
            SettingsView()
        }
        .sheet(isPresented: $showEventSheet) {
            EventModeSheet()
        }
        .animation(.spring(response: 0.4, dampingFraction: 0.8), value: eventManager.isReceiverActive)
        .animation(.spring(response: 0.4, dampingFraction: 0.8), value: eventManager.isLive)
    }

    // MARK: - Event Status Banner

    private var eventStatusBanner: some View {
        HStack(spacing: 12) {
            GlowingDotView(color: .softRose)

            VStack(alignment: .leading, spacing: 2) {
                HStack(spacing: 6) {
                    Text("EVENT LIVE")
                        .font(.system(size: 10, weight: .black))
                        .tracking(1.5)
                        .foregroundColor(.softRose)

                    Text("·")
                        .foregroundColor(.white.opacity(0.3))

                    Text(eventManager.eventCode)
                        .font(.system(size: 10, weight: .heavy, design: .monospaced))
                        .tracking(2)
                        .foregroundColor(.white.opacity(0.7))
                }

                HStack(spacing: 8) {
                    Label("\(eventPeerManager.connectedPeerCount)", systemImage: "person.2.fill")
                        .font(.system(size: 10, weight: .bold))
                        .foregroundColor(.white.opacity(0.5))

                    Label("\(eventPeerManager.receivedCards.count)", systemImage: "rectangle.stack.fill")
                        .font(.system(size: 10, weight: .bold))
                        .foregroundColor(.white.opacity(0.5))
                }
            }

            Spacer()

            Button {
                if eventManager.isHost {
                    eventPeerManager.sendTerminationSignal()
                }
                eventManager.stop()
                eventPeerManager.stop()
                UIImpactFeedbackGenerator(style: .medium).impactOccurred()
            } label: {
                Text("STOP")
                    .font(.system(size: 10, weight: .black))
                    .tracking(1)
                    .foregroundColor(.black)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 8)
                    .background(Capsule().fill(Color.softRose))
            }
        }
        .padding(.horizontal, 16)
        .frame(maxWidth: .infinity)
        .frame(minHeight: 52)
        .background(
            Capsule()
                .fill(Color.softRose.opacity(0.08))
                .overlay(
                    Capsule()
                        .stroke(Color.softRose.opacity(0.25), lineWidth: 1)
                )
        )
        .transition(.move(edge: .top).combined(with: .opacity))
    }

    // MARK: - Receiver Status Banner

    private var receiverStatusBanner: some View {
        HStack(spacing: 12) {
            GlowingDotView(color: .skyBlue)

            Text(peerManager.isConnected
                 ? "CONNECTED — RECEIVING CARD"
                 : "YOUR DEVICE IS VISIBLE TO OTHERS")
                .font(.system(size: 10, weight: .black, design: .default))
                .tracking(1.5)
                .foregroundColor(.skyBlue.opacity(0.9))
        }
        .frame(maxWidth: .infinity)
        .frame(height: 44)
        .background(
            Capsule()
                .fill(Color.skyBlue.opacity(peerManager.isConnected ? 0.12 : 0.05))
                .overlay(
                    Capsule()
                        .stroke(Color.skyBlue.opacity(peerManager.isConnected ? 0.35 : 0.15), lineWidth: 1)
                )
        )
        .transition(.move(edge: .top).combined(with: .opacity))
        .animation(.easeInOut(duration: 0.3), value: peerManager.isConnected)
    }
}

struct GlowingDotView: View {
    var color: Color = .skyBlue
    @State private var isAnimating = false

    var body: some View {
        ZStack {
            // Outer glowing ring
            Circle()
                .fill(color)
                .frame(width: 14, height: 14)
                .scaleEffect(isAnimating ? 2.5 : 1.0)
                .opacity(isAnimating ? 0 : 0.6)

            // Inner solid dot
            Circle()
                .fill(color)
                .frame(width: 8, height: 8)
                .shadow(color: color, radius: 4)
        }
        .onAppear {
            withAnimation(.easeInOut(duration: 1.5).repeatForever(autoreverses: false)) {
                isAnimating = true
            }
        }
    }
}
