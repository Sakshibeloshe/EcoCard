import SwiftUI

struct CardFrontView: View {
    let card: CardModel
    
    var body: some View {
        ZStack {
            PremiumCardPattern(backgroundColor: backgroundColor)
                .clipShape(RoundedRectangle(cornerRadius: 32, style: .continuous))
                .shadow(color: .black.opacity(0.15), radius: 18, x: 0, y: 10)

            VStack(alignment: .leading, spacing: 14) {
                
                // Top row: Name + type icon
                HStack(alignment: .top) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(card.fullName)
                            .font(.system(size: 28, weight: .bold, design: .rounded))
                            .foregroundStyle(Color.charcoalGrey)
                            .lineLimit(1)
                            .minimumScaleFactor(0.8)

                        Text(frontSubtitle)
                            .font(.system(size: 18, weight: .medium, design: .rounded))
                            .foregroundStyle(Color.charcoalGrey.opacity(0.6))
                            .lineLimit(1)
                    }

                    Spacer()

                    Image(systemName: card.type.icon)
                        .font(.system(size: 20, weight: .bold))
                        .foregroundStyle(Color.charcoalGrey.opacity(0.6))
                        .frame(width: 48, height: 48)
                        .background(Color.charcoalGrey.opacity(0.1))
                        .clipShape(Circle())
                }

                Spacer(minLength: 0)

                // Bottom: primary + secondary action row
                CardActionRow(
                    primary: card.primaryAction(),
                    secondary: card.secondaryAction()
                )
            }
            .padding(22)
        }
        .frame(height: 210)
        .padding(.horizontal, 16)
    }
    
    private var backgroundColor: Color {
        if card.isReceived { return .skyBlue }
        switch card.type {
        case .personal: return .softRose
        case .business: return .freshLime
        case .social: return .skyBlue
        case .event: return .lavenderPurple
        case .blank: return .softTerracotta
        }
    }

    private var frontSubtitle: String {
        // Role + org in one line
        let role = card.subtitle ?? ""
        let org = card.org ?? ""

        if !role.isEmpty && !org.isEmpty {
            return "\(role) • \(org)"
        } else if !role.isEmpty {
            return role
        } else if !org.isEmpty {
            return org
        } else {
            return card.type.displayName
        }
    }
}
