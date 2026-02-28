import SwiftUI

/// A button style that scales down slightly on press and bounces back,
/// giving cards a premium tactile feel.
struct CardPressButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.97 : 1.0)
            .brightness(configuration.isPressed ? -0.03 : 0)
            .animation(
                configuration.isPressed
                    ? .easeOut(duration: 0.12)
                    : .spring(response: 0.35, dampingFraction: 0.6),
                value: configuration.isPressed
            )
    }
}
