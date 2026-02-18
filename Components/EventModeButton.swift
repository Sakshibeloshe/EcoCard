import SwiftUI

struct EventModeButton: View {
    let isLive: Bool
    
    var body: some View {
        HStack(spacing: 6) {
            Image(systemName: "bolt.fill")
                .font(.system(size: 12, weight: .bold))

            Text(isLive ? "EVENT LIVE" : "EVENT MODE")
                .font(.system(size: 10, weight: .black, design: .default))
                .tracking(1)
        }
        .foregroundColor(isLive ? .black : .white.opacity(0.6))
        .padding(.horizontal, 12)
        .frame(height: 32)
        .background(
            ZStack {
                if isLive {
                    Capsule()
                        .fill(Color.softRose)
                        .shadow(color: Color.softRose.opacity(0.8), radius: 8)
                } else {
                    Capsule()
                        .fill(Color.white.opacity(0.05))
                        .overlay(
                            Capsule()
                                .stroke(Color.white.opacity(0.08), lineWidth: 0.5)
                        )

//                    Capsule()
//                        .fill(Color.white.opacity(0.05))
//                        .stroke(Color.white.opacity(0.08), lineWidth: 0.5)
                }
            }
        )
    }
}
