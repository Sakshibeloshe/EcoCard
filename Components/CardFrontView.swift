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

            VStack(alignment: .leading, spacing: 0) {
                // Top Row: Name/Subtitle and Photo
                HStack(alignment: .top) {
                    VStack(alignment: .leading, spacing: 6) {
                        Text(card.fullName)
                            .font(.system(size: 32, weight: .bold, design: .rounded))
                            .foregroundStyle(Color.charcoalGrey)
                            .lineLimit(1)
                            .minimumScaleFactor(0.6)

                        if let pronouns = card.pronouns, !pronouns.isEmpty {
                            Text(pronouns.uppercased())
                                .font(.system(size: 13, weight: .bold))
                                .foregroundStyle(Color.charcoalGrey.opacity(0.4))
                                .tracking(1.0)
                        } else if let subtitle = card.subtitle, !subtitle.isEmpty {
                            Text(subtitle.uppercased())
                                .font(.system(size: 13, weight: .bold, design: .rounded))
                                .foregroundStyle(Color.charcoalGrey.opacity(0.4))
                                .tracking(1.0)
                        }
                    }

                    Spacer()

                    // Photo Slot
                    ZStack {
                        RoundedRectangle(cornerRadius: 24, style: .continuous)
                            .fill(Color.charcoalGrey.opacity(0.08))
                            .frame(width: 80, height: 80)
                            .shadow(color: .black.opacity(0.1), radius: 10, x: 0, y: 4)

                        if let photoString = card.photo,
                           let data = Data(base64Encoded: photoString.replacingOccurrences(of: "data:image/jpeg;base64,", with: "")),
                           let uiImage = UIImage(data: data) {
                            Image(uiImage: uiImage)
                                .resizable()
                                .scaledToFill()
                                .frame(width: 80, height: 80)
                                .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
                        }
                    }
                }

                Spacer()

                // Bottom Left: Bio/Contact Info
                VStack(alignment: .leading, spacing: 4) {
                    if let subtitle = card.subtitle, !subtitle.isEmpty, card.pronouns != nil {
                        Text(subtitle.uppercased())
                            .font(.system(size: 13, weight: .bold, design: .rounded))
                            .foregroundStyle(Color.charcoalGrey.opacity(0.6))
                            .tracking(1.0)
                    }

                    if let org = card.org, !org.isEmpty {
                        Text(org.uppercased())
                            .font(.system(size: 14, weight: .bold, design: .rounded))
                            .foregroundStyle(Color.charcoalGrey.opacity(0.8))
                            .tracking(1.5)
                            .padding(.bottom, 2)
                    }

                    VStack(alignment: .leading, spacing: 2) {
                        if let email = card.email, !email.isEmpty {
                            Text(email)
                                .font(.system(size: 14, weight: .medium, design: .rounded))
                                .foregroundStyle(Color.charcoalGrey.opacity(0.6))
                        }
                        if let website = card.website, !website.isEmpty {
                            Text(website)
                                .font(.system(size: 14, weight: .medium, design: .rounded))
                                .foregroundStyle(Color.charcoalGrey.opacity(0.6))
                        }
                    }
                }
            }
            .padding(.horizontal, 32)
            .padding(.top, 32)
            .padding(.bottom, 60) // Increased bottom padding to avoid overlap with label

            // Border
            RoundedRectangle(cornerRadius: 32, style: .continuous)
                .stroke(Color.black.opacity(0.08), lineWidth: 1.5)

            // Card Type Label (Attached to Bottom)
            VStack {
                Spacer()
                Text(card.type.rawValue.uppercased())
                    .font(.system(size: 13, weight: .bold))
                    .foregroundStyle(.white.opacity(0.7))
                    .tracking(3.0)
                    .frame(width: 140, height: 44) // Specific size for the bottom tab
                    .background(Color.black.opacity(0.85))
                    .clipShape(
                        .rect(
                            topLeadingRadius: 20,
                            bottomLeadingRadius: 0,
                            bottomTrailingRadius: 0,
                            topTrailingRadius: 20
                        )
                    )
            }
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
