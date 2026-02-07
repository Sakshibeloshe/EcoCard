
import SwiftUI

struct TopNavBar: View {
    @ObservedObject var eventManager: EventModeManager
    @Binding var showEventSheet: Bool
    
    var body: some View {
        HStack(spacing: 14) {

            // profile circle
            Circle()
                .fill(Color.white.opacity(0.18))
                .frame(width: 44, height: 44)
                .overlay(Image(systemName: "person.fill").foregroundStyle(.white.opacity(0.6)))

            Text("Emily Parker")
                .font(.system(size: 18, weight: .semibold))
                .foregroundColor(.white)

            Spacer()

            Button {
                if eventManager.isLive {
                    eventManager.stop()
                    UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                } else {
                    showEventSheet = true
                    UIImpactFeedbackGenerator(style: .light).impactOccurred()
                }
            } label: {
                EventModePill(isLive: eventManager.isLive)
            }

            Button {
                // settings
            } label: {
                Image(systemName: "gearshape.fill")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(.white.opacity(0.75))
                    .frame(width: 42, height: 42)
                    .background(.ultraThinMaterial)
                    .clipShape(Circle())
            }
        }
    }
}
