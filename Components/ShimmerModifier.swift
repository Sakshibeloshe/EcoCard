import SwiftUI

/// Sweeps a diagonal highlight gradient across the view on repeat.
/// Use `.modifier(ShimmerModifier(isActive: true))` on a card.
struct ShimmerModifier: ViewModifier {
    var isActive: Bool
    @State private var phase: CGFloat = -1

    func body(content: Content) -> some View {
        content.overlay(
            Group {
                if isActive {
                    GeometryReader { geo in
                        let w = geo.size.width
                        LinearGradient(
                            stops: [
                                .init(color: .clear,                     location: 0),
                                .init(color: .white.opacity(0.18),       location: 0.45),
                                .init(color: .white.opacity(0.28),       location: 0.5),
                                .init(color: .white.opacity(0.18),       location: 0.55),
                                .init(color: .clear,                     location: 1),
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                        .frame(width: w * 2.5)
                        .offset(x: phase * w * 2.5)
                        .blendMode(.screen)
                    }
                    .clipShape(RoundedRectangle(cornerRadius: 32, style: .continuous))
                    .allowsHitTesting(false)
                    .onAppear { startShimmer() }
                }
            }
        )
    }

    private func startShimmer() {
        phase = -1
        withAnimation(
            .linear(duration: 2.0)
            .repeatForever(autoreverses: false)
        ) {
            phase = 1
        }
    }
}

extension View {
    func shimmer(isActive: Bool = true) -> some View {
        modifier(ShimmerModifier(isActive: isActive))
    }
}
