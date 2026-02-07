import SwiftUI

struct CardFrontView: View {
    let card: CardModel
    
    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 28, style: .continuous)
                .fill(card.uiColor.gradient)
                .shadow(color: .black.opacity(0.15), radius: 18, x: 0, y: 10)

            VStack(alignment: .leading, spacing: 14) {
                
                // Top row: Name + type icon
                HStack(alignment: .top) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(card.fullName)
                            .font(.system(size: 26, weight: .heavy, design: .rounded))
                            .foregroundStyle(.white)
                            .lineLimit(1)
                            .minimumScaleFactor(0.8)

                        Text(frontSubtitle)
                            .font(.system(size: 16, weight: .semibold, design: .rounded))
                            .foregroundStyle(.white.opacity(0.85))
                            .lineLimit(1)
                    }

                    Spacer()

                    Image(systemName: card.type.icon)
                        .font(.system(size: 18, weight: .bold))
                        .foregroundStyle(.white.opacity(0.8))
                        .padding(10)
                        .background(.white.opacity(0.15))
                        .clipShape(Circle())
                }

                // Intent badge (your USP)
                if let intent = card.intent, !intent.isEmpty {
                    Text(intent)
                        .font(.system(size: 14, weight: .bold, design: .rounded))
                        .foregroundStyle(.white)
                        .padding(.horizontal, 14)
                        .padding(.vertical, 9)
                        .background(.white.opacity(0.18))
                        .clipShape(Capsule())
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
