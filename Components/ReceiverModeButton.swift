import SwiftUI

struct ReceiverModeButton: View {
    let isLive: Bool
    @State private var pulse = false
    @State private var ripple = false

    var body: some View {
        ZStack {
            // Expanding ripple ring — only when live
            if isLive {
                Circle()
                    .stroke(Color.skyBlue.opacity(ripple ? 0 : 0.4), lineWidth: 1.5)
                    .frame(width: 80, height: 80)
                    .scaleEffect(ripple ? 2.2 : 1.0)
                    .opacity(ripple ? 0 : 1)
                    .animation(
                        .easeOut(duration: 1.4).repeatForever(autoreverses: false),
                        value: ripple
                    )
            }

            HStack(spacing: 6) {
                Image(systemName: "antenna.radiowaves.left.and.right")
                    .font(.system(size: 14, weight: .bold))

                Text(isLive ? "RECEIVING LIVE" : "RECEIVER MODE")
                    .font(.system(size: 10, weight: .black, design: .default))
                    .tracking(1)
            }
            .foregroundColor(isLive ? .black : .white.opacity(0.8))
            .padding(.horizontal, 20)
            .frame(height: 44)
            .background(
                ZStack {
                    if isLive {
                        Capsule()
                            .fill(Color.skyBlue)
                            .shadow(color: Color.skyBlue.opacity(0.6), radius: 14, x: 0, y: 0)
                    } else {
                        Capsule()
                            .fill(Color.white.opacity(0.06))
                            .overlay(
                                Capsule()
                                    .stroke(Color.white.opacity(0.12), lineWidth: 1)
                            )
                    }
                }
            )
            .scaleEffect(isLive && pulse ? 1.04 : 1.0)
            .animation(
                isLive
                    ? .easeInOut(duration: 0.8).repeatForever(autoreverses: true)
                    : .default,
                value: pulse
            )
        }
        .onChange(of: isLive) { _, live in
            if live {
                pulse = false
                ripple = false
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
                    pulse = true
                    ripple = true
                }
            } else {
                pulse = false
                ripple = false
            }
        }
        .onAppear {
            if isLive {
                pulse = true
                ripple = true
            }
        }
    }
}
