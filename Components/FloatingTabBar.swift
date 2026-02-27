import SwiftUI

struct FloatingTabBar: View {
    @Binding var selectedTab: Tab

    var body: some View {
        VStack {
            Spacer()

            HStack(spacing: 12) {
                TabButton(
                    icon: "rectangle.fill",
                    label: "My Cards",
                    isSelected: selectedTab == .myCards,
                    activeColor: .freshLime
                ) {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.65)) {
                        selectedTab = .myCards
                    }
                    UIImpactFeedbackGenerator(style: .soft).impactOccurred()
                }

                TabButton(
                    icon: "plus",
                    label: "Add Card",
                    isSelected: selectedTab == .add,
                    activeColor: .softRose
                ) {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.65)) {
                        selectedTab = .add
                    }
                    UIImpactFeedbackGenerator(style: .rigid).impactOccurred()
                }

                TabButton(
                    icon: "person.2.fill",
                    label: "Inbox",
                    isSelected: selectedTab == .inbox,
                    activeColor: .skyBlue
                ) {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.65)) {
                        selectedTab = .inbox
                    }
                    UIImpactFeedbackGenerator(style: .soft).impactOccurred()
                }
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 10)
            .background(.ultraThinMaterial)
            .background(Color.charcoalGrey.opacity(0.8))
            .clipShape(Capsule())
            .overlay(
                Capsule()
                    .stroke(Color.white.opacity(0.1), lineWidth: 1)
            )
            // Elevated shadow with more depth
            .shadow(color: .black.opacity(0.5), radius: 28, x: 0, y: 14)
            .shadow(color: .black.opacity(0.2), radius: 6, x: 0, y: 3)
            .padding(.bottom, 10)
        }
    }
}

struct TabButton: View {
    let icon: String
    let label: String
    let isSelected: Bool
    let activeColor: Color
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 4) {
                Image(systemName: icon)
                    .font(.system(size: 18, weight: .bold))

                Text(label)
                    .font(.system(size: 10, weight: .bold, design: .rounded))
            }
            .foregroundColor(isSelected ? Color.charcoalGrey : Color.white.opacity(0.4))
            .frame(width: 80, height: 58)
            .background(isSelected ? activeColor : Color.clear)
            // Active tab glow
            .shadow(
                color: isSelected ? activeColor.opacity(0.55) : .clear,
                radius: 10, x: 0, y: 0
            )
            .clipShape(Capsule())
            .accessibilityLabel(Text(isSelected ? "Selected \(label) tab" : "\(label) tab"))
        }
        .scaleEffect(isSelected ? 1.05 : 1.0)
        .animation(.spring(response: 0.3, dampingFraction: 0.6), value: isSelected)
    }
}
