import SwiftUI

struct CardActionRow: View {
    let primary: CardAction?
    let secondary: CardAction?
    
    @Environment(\.openURL) private var openURL
    
    var body: some View {
        HStack(spacing: 12) {
            
            if let primary {
                actionButton(primary, isPrimary: true)
            }
            
            if let secondary {
                actionButton(secondary, isPrimary: false)
            }
        }
    }
    
    private func actionButton(_ action: CardAction, isPrimary: Bool) -> some View {
        Button {
            if let url = action.url {
                openURL(url)
            }
        } label: {
            HStack(spacing: 8) {
                Image(systemName: action.systemIcon)
                    .font(.system(size: 14, weight: .bold))
                
                Text(action.label)
                    .font(.system(size: 14, weight: .bold, design: .rounded))
            }
            .foregroundStyle(isPrimary ? .black : .white)
            .padding(.horizontal, 14)
            .padding(.vertical, 11)
            .frame(maxWidth: .infinity)
            .background(isPrimary ? .white : .white.opacity(0.18))
            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
        }
        .buttonStyle(.plain)
    }
}
