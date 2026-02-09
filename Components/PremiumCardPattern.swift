import SwiftUI

struct PremiumCardPattern: View {
    var backgroundColor: Color
    
    var body: some View {
        ZStack {
            // 1. The Base Color
            backgroundColor
            
            // 2. The Mesh Gradient (Creates the soft "glow" in the corner)
            Canvas { context, size in
                context.fill(Path(CGRect(origin: .zero, size: size)), with: .color(backgroundColor))
                
                // Add a subtle top-right highlight
                let highlightRect = CGRect(x: size.width * 0.4, y: -size.height * 0.2, 
                                          width: size.width * 0.8, height: size.height * 0.8)
                context.fill(Path(ellipseIn: highlightRect), 
                            with: .radialGradient(Gradient(colors: [.white.opacity(0.3), .clear]),
                            center: CGPoint(x: size.width * 0.8, y: 0),
                            startRadius: 0, endRadius: size.width * 0.6))
            }
            .blur(radius: 40)
            
            // 3. The Grain/Noise Overlay
            // Note: If "noise_texture" is missing, this will just be a subtle opacity layer
            Rectangle()
                .fill(Color.black.opacity(0.03))
                .overlay(
                    Image("noise_texture") // Add a grain PNG to your assets
                        .resizable(resizingMode: .tile)
                        .opacity(0.05)
                        .blendMode(.overlay)
                )
        }
    }
}
