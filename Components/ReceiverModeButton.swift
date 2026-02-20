import SwiftUI

struct ReceiverModeButton: View {
    let isLive: Bool

    var body: some View {
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
                        .shadow(color: Color.skyBlue.opacity(0.8), radius: 10)
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
    }
}
