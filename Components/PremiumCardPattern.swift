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
            
            // 2.5. The Dot Grid Pattern (Professional Texture)
            Canvas { context, size in
                let dotSize: CGFloat = 1.6
                let spacing: CGFloat = 10.0
                
                for x in stride(from: spacing/2, to: size.width, by: spacing) {
                    for y in stride(from: spacing/2, to: size.height, by: spacing) {
                        let rect = CGRect(x: x, y: y, width: dotSize, height: dotSize)
                        context.fill(Path(ellipseIn: rect), with: .color(.black.opacity(0.06)))
                    }
                }
            }
            .blendMode(.multiply)
            
            // 3. The Grain/Noise Overlay
            // Note: If "noise_texture" is missing, this will just be a subtle opacity layer
            Rectangle()
                .fill(Color.black.opacity(0.03))
                .overlay(
                    Image("noise_texture", bundle: .module)
                        .resizable(resizingMode: .tile)
                        .opacity(0.05)
                        .blendMode(.overlay)
                )
        }
    }
}
