
import SwiftUI

struct TopNavBar: View {
    @EnvironmentObject var eventManager: EventModeManager
    @State private var showSettings = false
    @State private var showEventSheet = false

    var body: some View {
        VStack(spacing: 0) {
            HStack(spacing: 8) {
                // Receiver Mode Button (Primary)
                Button {
                    eventManager.toggleReceiver()
                    UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                } label: {
                    ReceiverModeButton(isLive: eventManager.isReceiverActive)
                }

                // Event Mode Button (Contextual)
                Button {
                    if eventManager.isLive {
                        eventManager.stop()
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
            // Banner section
            if eventManager.isReceiverActive {
                HStack(spacing: 12) {
                    GlowingDotView()
                    
                    Text("YOUR DEVICE IS VISIBLE TO OTHERS")
                        .font(.system(size: 10, weight: .black, design: .default))
                        .tracking(1.5)
                        .foregroundColor(.skyBlue.opacity(0.9))
                }
                .frame(maxWidth: .infinity)
                .frame(height: 44)
                .background(
                    Capsule()
                        .fill(Color.skyBlue.opacity(0.05))
                        .overlay(
                            Capsule()
                                .stroke(Color.skyBlue.opacity(0.15), lineWidth: 1)
                        )
                )
                .transition(.move(edge: .top).combined(with: .opacity))
            }
        }
        .sheet(isPresented: $showSettings) {
            SettingsView()
        }
        .sheet(isPresented: $showEventSheet) {
            EventModeSheet()
        }
        .animation(.spring(response: 0.4, dampingFraction: 0.8), value: eventManager.isReceiverActive)
    }
}

struct GlowingDotView: View {
    @State private var isAnimating = false
    
    var body: some View {
        ZStack {
            // Outer glowing ring
            Circle()
                .fill(Color.skyBlue)
                .frame(width: 14, height: 14)
                .scaleEffect(isAnimating ? 2.5 : 1.0)
                .opacity(isAnimating ? 0 : 0.6)
            
            // Inner solid dot
            Circle()
                .fill(Color.skyBlue)
                .frame(width: 8, height: 8)
                .shadow(color: Color.skyBlue, radius: 4)
        }
        .onAppear {
            withAnimation(.easeInOut(duration: 1.5).repeatForever(autoreverses: false)) {
                isAnimating = true
            }
        }
    }
}
