import SwiftUI

struct CardFrontView: View {
    let card: CardModel
    var isSelected: Bool = false

    var body: some View {
        ZStack {
            PremiumCardPattern(backgroundColor: card.theme.color)
                .clipShape(RoundedRectangle(cornerRadius: 36, style: .continuous))
                // Ambient broad shadow
                .shadow(color: card.theme.color.opacity(0.15), radius: 30, x: 0, y: 16)
                // Crisp lifted shadow
                .shadow(color: .black.opacity(0.25), radius: 10, x: 0, y: 6)

            VStack(alignment: .leading, spacing: 0) {
                // Top Row: Name/Title and Photo Slot
                HStack(alignment: .top) {
                    VStack(alignment: .leading, spacing: 6) {
                        Text(card.fullName)
                            .font(.system(size: 36, weight: .bold, design: .default))
                            .foregroundStyle(Color.charcoalGrey)
                            .lineLimit(1)
                            .minimumScaleFactor(0.6)

                        if let subtitle = card.subtitle, !subtitle.isEmpty {
                            Text(subtitle.uppercased())
                                .font(.system(size: 11, weight: .black, design: .default))
                                .foregroundStyle(Color.charcoalGrey.opacity(0.35))
                                .tracking(2.0)
                        }
                    }

                    Spacer()

                    // Photo Slot (Glassmorphic Rounded Square)
                    ZStack {
                        RoundedRectangle(cornerRadius: 24, style: .continuous)
                            .fill(Color.charcoalGrey.opacity(0.06))
                            .frame(width: 84, height: 84)
                            .overlay(
                                RoundedRectangle(cornerRadius: 24, style: .continuous)
                                    .stroke(Color.black.opacity(0.04), lineWidth: 1)
                            )

                        if let photoString = card.photo,
                           let data = Data(base64Encoded: photoString.replacingOccurrences(of: "data:image/jpeg;base64,", with: "")),
                           let uiImage = UIImage(data: data) {
                            Image(uiImage: uiImage)
                                .resizable()
                                .scaledToFill()
                                .frame(width: 84, height: 84)
                                .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
                        }
                    }
                }

                Spacer()

                // Bottom Row: Company Info and Send Action
                HStack(alignment: .bottom) {
                    VStack(alignment: .leading, spacing: 6) {
                        if let org = card.org, !org.isEmpty {
                            Text(org.uppercased())
                                .font(.system(size: 12, weight: .black, design: .default))
                                .foregroundStyle(Color.charcoalGrey.opacity(0.7))
                                .tracking(1.5)
                        }

                        VStack(alignment: .leading, spacing: 2) {
                            if let email = card.email, !email.isEmpty {
                                Text(email)
                                    .font(.system(size: 13, weight: .medium, design: .default))
                                    .foregroundStyle(Color.charcoalGrey.opacity(0.5))
                            }
                            if let website = card.website, !website.isEmpty {
                                Text(website)
                                    .font(.system(size: 13, weight: .medium, design: .default))
                                    .foregroundStyle(Color.charcoalGrey.opacity(0.5))
                            }
                        }
                    }

                    Spacer()

                    // Send Action Icon
                    ZStack {
                        Circle()
                            .fill(Color.white.opacity(0.3))
                            .frame(width: 48, height: 48)
                            .overlay(Circle().stroke(Color.black.opacity(0.05), lineWidth: 1))
                            .shadow(color: .black.opacity(0.08), radius: 8, x: 0, y: 4)

                        Image(systemName: "paperplane")
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundStyle(Color.charcoalGrey)
                    }
                }
            }
            .padding(32)

            // Edge Border
            RoundedRectangle(cornerRadius: 36, style: .continuous)
                .stroke(Color.black.opacity(0.05), lineWidth: 1)
        }
        .aspectRatio(1.5, contentMode: .fit)
        .clipShape(RoundedRectangle(cornerRadius: 36, style: .continuous))
        // Selected state: slight lift
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
