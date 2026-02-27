import SwiftUI

struct CardFrontView: View {
    let card: CardModel
    var isSelected: Bool = false

    var body: some View {
        ZStack {
            PremiumCardPattern(backgroundColor: card.theme.color)
                .clipShape(RoundedRectangle(cornerRadius: 32, style: .continuous))
                // Ambient broad shadow
                .shadow(color: card.theme.color.opacity(0.25), radius: 30, x: 0, y: 16)
                // Crisp lifted shadow
                .shadow(color: .black.opacity(0.35), radius: 10, x: 0, y: 6)

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

                        // Role subtitle — small-caps weight for hierarchy
                        Text(frontSubtitle.uppercased())
                            .font(.system(size: 13, weight: .semibold, design: .rounded))
                            .foregroundStyle(Color.charcoalGrey.opacity(0.55))
                            .tracking(0.8)
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

                // Middle Section: Intent — lighter opacity for visual hierarchy
                if let intent = card.intent, !intent.isEmpty {
                    Text(intent.uppercased())
                        .font(.system(size: 11, weight: .bold))
                        .foregroundStyle(Color.charcoalGrey.opacity(0.6))
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
            .padding(32)

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

            // Border
            RoundedRectangle(cornerRadius: 32, style: .continuous)
                .stroke(Color.black.opacity(0.1), lineWidth: 2)
        }
        .aspectRatio(1.5, contentMode: .fit)
        .clipShape(RoundedRectangle(cornerRadius: 32, style: .continuous))
        .padding(.horizontal, 20)
        // Selected state: slight lift + shimmer
        .scaleEffect(isSelected ? 1.02 : 1.0)
        .animation(.spring(response: 0.35, dampingFraction: 0.65), value: isSelected)
        .shimmer(isActive: isSelected)
    }

    private var frontSubtitle: String {
        let role = card.subtitle ?? ""
        var org = card.org ?? ""

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
