import SwiftUI

struct CardFrontView: View {
    let card: CardModel
    
    var body: some View {
        ZStack {
            PremiumCardPattern(backgroundColor: card.theme.color)
                .clipShape(RoundedRectangle(cornerRadius: 32, style: .continuous))
                .shadow(color: .black.opacity(0.15), radius: 18, x: 0, y: 10)

            VStack(alignment: .leading, spacing: 14) {
                
                // Top row: Name + type icon
                HStack(alignment: .top) {
                    VStack(alignment: .leading, spacing: 4) {
                        HStack(alignment: .firstTextBaseline, spacing: 8) {
                            Text(card.fullName)
                                .font(.system(size: 28, weight: .bold, design: .rounded))
                                .foregroundStyle(Color.charcoalGrey)
                                .lineLimit(1)
                                .minimumScaleFactor(0.8)
                            
                            if let pronouns = card.pronouns, !pronouns.isEmpty {
                                Text(pronouns.uppercased())
                                    .font(.system(size: 13, weight: .bold))
                                    .foregroundStyle(Color.charcoalGrey.opacity(0.4))
                                    .tracking(0.5)
                            }
                        }

                        Text(frontSubtitle)
                            .font(.system(size: 18, weight: .medium, design: .rounded))
                            .foregroundStyle(Color.charcoalGrey.opacity(0.6))
                            .lineLimit(1)
                    }

                    Spacer()

                    Image(systemName: card.type.icon)
                        .font(.system(size: 18, weight: .bold))
                        .foregroundStyle(Color.charcoalGrey.opacity(0.6))
                        .frame(width: 44, height: 44)
                        .background(Color.charcoalGrey.opacity(0.08))
                        .clipShape(Circle())
                }

                Spacer(minLength: 0)

                // Middle Section: Intent
                if let intent = card.intent, !intent.isEmpty {
                    Text(intent.uppercased())
                        .font(.system(size: 11, weight: .bold))
                        .foregroundStyle(Color.charcoalGrey.opacity(0.8))
                        .padding(.horizontal, 12)
                        .padding(.vertical, 8)
                        .background(Color.charcoalGrey.opacity(0.05))
                        .clipShape(Capsule())
                        .padding(.bottom, 4)
                }

                // Bottom: primary + secondary action row
                CardActionRow(
                    primary: card.primaryAction(),
                    secondary: card.secondaryAction()
                )
            }
            .padding(32) // Inner Padding: 32pt

            // Type Tag (Center Bottom)
            VStack {
                Spacer()
                Text(card.type.displayName.uppercased())
                    .font(.system(size: 10, weight: .black))
                    .foregroundStyle(Color.white)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                    .background(Color.black)
                    .clipShape(UnevenRoundedRectangle(topLeadingRadius: 10, bottomLeadingRadius: 0, bottomTrailingRadius: 0, topTrailingRadius: 10, style: .continuous))
            }
            
            // Border Width: 2pt
            RoundedRectangle(cornerRadius: 32, style: .continuous)
                .stroke(Color.black.opacity(0.1), lineWidth: 2)
        }
        .aspectRatio(1.5, contentMode: .fit) 
        .clipShape(RoundedRectangle(cornerRadius: 32, style: .continuous))
        .padding(.horizontal, 20)
    }
    
    // backgroundColor removed as we use card.theme.color directly
    
    private var frontSubtitle: String {
        // Role + org in one line
        let role = card.subtitle ?? ""
        var org = card.org ?? ""
        
        // Specific mapping for types
        if card.type == .personal {
            org = card.locationCity ?? ""
        } else if card.type == .social {
            org = card.emojiTags ?? ""
        }

        if !role.isEmpty && !org.isEmpty {
            return "\(role) • \(org)"
        } else if !role.isEmpty {
            return role
        } else if !org.isEmpty {
            return org
        } else {
            return ""
        }
    }
}
