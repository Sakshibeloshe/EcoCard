import SwiftUI

struct ThemeColorPicker: View {
    @Binding var selectedTheme: CardTheme
    
    var body: some View {
        HStack(spacing: 16) {
            ForEach(CardTheme.allCases) { theme in
                Button {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                        selectedTheme = theme
                    }
                    UIImpactFeedbackGenerator(style: .light).impactOccurred()
                } label: {
                    Circle()
                        .fill(theme.color.gradient)
                        .frame(width: 60, height: 60)
                        .overlay(
                            Circle()
                                .stroke(.white.opacity(0.3), lineWidth: selectedTheme == theme ? 3 : 0)
                        )
                        .scaleEffect(selectedTheme == theme ? 1.1 : 1.0)
                        .shadow(color: selectedTheme == theme ? theme.color.opacity(0.4) : .clear, radius: 12, x: 0, y: 6)
                }
            }
        }
    }
}
