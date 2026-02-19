
import SwiftUI

struct ShareCardView: View {
    @Environment(\.dismiss) var dismiss
    let card: CardModel
    
    @State private var shareMode: ShareMode = .touch
    @State private var isAnimating = false
    @State private var showTouchMode = false
    
    enum ShareMode {
        case touch, qr
    }

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            
            VStack {
                // Top Bar
                HStack {
                    Button("Cancel") { dismiss() }
                        .foregroundColor(.white.opacity(0.5))
                        .font(.system(size: 16, weight: .medium))
                    
                    Spacer()
                    
                    HStack(spacing: 0) {
                        toggleButton(title: "TOUCH", mode: .touch)
                        toggleButton(title: "QR", mode: .qr)
                    }
                    .padding(4)
                    .background(Color.white.opacity(0.1))
                    .clipShape(Capsule())
                    
                    Spacer()
                    
                    Button {
                        // System share sheet — future
                    } label: {
                        Image(systemName: "square.and.arrow.up")
                            .font(.system(size: 18, weight: .medium))
                            .foregroundColor(.white.opacity(0.5))
                    }
                }
                .padding(.horizontal, 20)
                .padding(.top, 20)

                Spacer()
                
                TabView(selection: $shareMode) {
                    touchPreviewView
                        .tag(ShareMode.touch)
                    
                    qrModeView
                        .tag(ShareMode.qr)
                }
                .tabViewStyle(.page(indexDisplayMode: .never))
                .frame(height: 500)
                
                Spacer()
            }
        }
        .fullScreenCover(isPresented: $showTouchMode) {
            TouchModeView(card: card)
        }
    }
    
    private func toggleButton(title: String, mode: ShareMode) -> some View {
        Button {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                shareMode = mode
            }
            UIImpactFeedbackGenerator(style: .light).impactOccurred()
        } label: {
            Text(title)
                .font(.system(size: 13, weight: .bold))
                .foregroundColor(shareMode == mode ? .black : .white)
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(
                    Capsule()
                        .fill(shareMode == mode ? Color.white : Color.clear)
                )
        }
    }
    
    // Touch preview — tap to launch real transfer session
    private var touchPreviewView: some View {
        VStack(spacing: 40) {
            CardView(card: card)
                .frame(width: 280)
                .scaleEffect(0.8)
                .shadow(color: card.uiColor.opacity(0.5), radius: 24)

            ZStack {
                ForEach(0..<3) { i in
                    Circle()
                        .stroke(card.uiColor.opacity(0.25), lineWidth: 1.5)
                        .frame(width: 100, height: 100)
                        .scaleEffect(isAnimating ? 3 : 1)
                        .opacity(isAnimating ? 0 : 1)
                        .animation(
                            Animation.easeOut(duration: 2.5)
                                .repeatForever(autoreverses: false)
                                .delay(Double(i) * 0.8),
                            value: isAnimating
                        )
                }
                Image(systemName: "wave.3.right")
                    .font(.system(size: 40))
                    .foregroundColor(.white)
            }
            .onAppear { isAnimating = true }

            VStack(spacing: 8) {
                Text("Tap to Start Transfer")
                    .font(.system(size: 22, weight: .bold, design: .rounded))
                    .foregroundColor(.white)

                Text("HOLD TOP EDGES TOGETHER")
                    .font(.system(size: 12, weight: .bold))
                    .foregroundColor(.white.opacity(0.35))
                    .tracking(1.4)
            }

            Button {
                showTouchMode = true
                UIImpactFeedbackGenerator(style: .medium).impactOccurred()
            } label: {
                Label("Start Sending", systemImage: "antenna.radiowaves.left.and.right")
                    .font(.system(size: 16, weight: .bold, design: .rounded))
                    .foregroundColor(.black)
                    .padding(.horizontal, 32)
                    .padding(.vertical, 14)
                    .background(Color.white)
                    .clipShape(Capsule())
            }
        }
    }
    
    private var qrModeView: some View {
        VStack(spacing: 40) {
             CardView(card: card)
                 .frame(width: 280)
                 .scaleEffect(0.8)

             Image(systemName: "qrcode")
                 .resizable()
                 .aspectRatio(contentMode: .fit)
                 .frame(width: 180, height: 180)
                 .foregroundColor(.white)
                 .padding(20)
                 .background(Color.white.opacity(0.1))
                 .cornerRadius(20)

             Text("SCAN TO CONNECT")
                 .font(.system(size: 12, weight: .bold))
                 .foregroundColor(.white.opacity(0.35))
                 .tracking(1.4)
        }
    }
}
