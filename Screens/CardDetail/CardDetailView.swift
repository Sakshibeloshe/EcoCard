import SwiftUI

struct CardDetailView: View {
    let card: CardModel
    
    @Environment(\.dismiss) private var dismiss
    @Environment(\.openURL) private var openURL
    
    @State private var noteText: String = ""
    @State private var isStarred: Bool = false
    
    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 18) {
                
                // Card front preview at top
                CardFrontView(card: card)
                    .padding(.top, 10)

                // Quick actions
                detailSection(title: "Quick Actions") {
                    VStack(spacing: 12) {
                        if let primary = card.primaryAction() {
                            bigAction(primary)
                        }
                        if let secondary = card.secondaryAction() {
                            bigAction(secondary)
                        }
                        
                        Button {
                            // You can implement contact export later
                        } label: {
                            Label("Save to Contacts", systemImage: "person.crop.circle.badge.plus")
                        }
                        .buttonStyle(SecondaryActionButtonStyle())
                    }
                }

                // Contact section
                detailSection(title: "Contact") {
                    VStack(spacing: 10) {
                        if let email = card.email, !email.isEmpty {
                            infoRow("Email", email, icon: "envelope.fill")
                        }
                        if let phone = card.phone, !phone.isEmpty {
                            infoRow("Phone", phone, icon: "phone.fill")
                        }
                        if let website = card.website, !website.isEmpty {
                            infoRow("Website", website, icon: "safari.fill")
                        }
                    }
                }

                // Social / Work section
                detailSection(title: "Links") {
                    VStack(spacing: 10) {
                        if let linkedIn = card.linkedin, !linkedIn.isEmpty {
                            linkRow("LinkedIn", linkedIn, icon: "link")
                        }
                        if let github = card.github, !github.isEmpty {
                            linkRow("GitHub", github, icon: "chevron.left.slash.chevron.right")
                        }
                        if let instagram = card.instagram, !instagram.isEmpty {
                            linkRow("Instagram", instagram, icon: "camera.fill")
                        }
                        if let portfolio = card.portfolio, !portfolio.isEmpty {
                            linkRow("Portfolio", portfolio, icon: "sparkles")
                        }
                    }
                }

                // Notes section
                detailSection(title: "My Notes") {
                    TextEditor(text: $noteText)
                        .frame(height: 110)
                        .padding(12)
                        .background(.white.opacity(0.06))
                        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                        .overlay(
                            RoundedRectangle(cornerRadius: 16, style: .continuous)
                                .stroke(.white.opacity(0.08))
                        )
                        .foregroundStyle(.white)
                }

                // Danger actions
                detailSection(title: "Manage") {
                    VStack(spacing: 12) {
                        Button {
                            isStarred.toggle()
                        } label: {
                            Label(isStarred ? "Unpin from Favorites" : "Pin to Favorites",
                                  systemImage: isStarred ? "star.slash.fill" : "star.fill")
                        }
                        .buttonStyle(SecondaryActionButtonStyle())

                        Button(role: .destructive) {
                            // delete logic later
                        } label: {
                            Label("Delete Card", systemImage: "trash.fill")
                        }
                        .buttonStyle(SecondaryActionButtonStyle())
                    }
                }

                Spacer(minLength: 60)
            }
        }
        .background(Color.black.ignoresSafeArea())
        .navigationBarBackButtonHidden(true)
        .toolbar {
            ToolbarItem(placement: .topBarLeading) {
                Button {
                    dismiss()
                } label: {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 16, weight: .bold))
                        .foregroundStyle(.white)
                        .padding(10)
                        .background(.white.opacity(0.06))
                        .clipShape(Circle())
                }
            }
            
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    // share later
                } label: {
                    Image(systemName: "square.and.arrow.up")
                        .foregroundStyle(.white.opacity(0.9))
                        .padding(10)
                        .background(.white.opacity(0.06))
                        .clipShape(Circle())
                }
            }
        }
    }
    
    // MARK: - Components
    
    private func detailSection<Content: View>(title: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(title.uppercased())
                .font(.system(size: 12, weight: .bold, design: .rounded))
                .foregroundStyle(.white.opacity(0.55))
                .padding(.horizontal, 20)

            VStack(spacing: 12) {
                content()
            }
            .padding(16)
            .background(.white.opacity(0.04))
            .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
            .padding(.horizontal, 16)
        }
    }
    
    private func bigAction(_ action: CardAction) -> some View {
        Button {
            if let url = action.url { openURL(url) }
        } label: {
            HStack {
                Label(action.label, systemImage: action.systemIcon)
                    .font(.system(size: 16, weight: .bold, design: .rounded))
                Spacer()
                Image(systemName: "arrow.up.right")
                    .font(.system(size: 14, weight: .bold))
            }
            .foregroundStyle(.black)
            .padding(.vertical, 14)
            .padding(.horizontal, 16)
            .background(.white)
            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        }
        .buttonStyle(.plain)
    }
    
    private func infoRow(_ title: String, _ value: String, icon: String) -> some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .foregroundStyle(.white.opacity(0.85))
                .frame(width: 28)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.system(size: 13, weight: .semibold, design: .rounded))
                    .foregroundStyle(.white.opacity(0.6))
                Text(value)
                    .font(.system(size: 16, weight: .bold, design: .rounded))
                    .foregroundStyle(.white)
            }
            Spacer()
        }
        .padding(.vertical, 6)
    }
    
    private func linkRow(_ title: String, _ value: String, icon: String) -> some View {
        Button {
            if let url = URL(string: value.hasPrefix("http") ? value : "https://\(value)") {
                openURL(url)
            }
        } label: {
            HStack(spacing: 12) {
                Image(systemName: icon)
                    .foregroundStyle(.white.opacity(0.85))
                    .frame(width: 28)
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(.system(size: 13, weight: .semibold, design: .rounded))
                        .foregroundStyle(.white.opacity(0.6))
                    Text(value)
                        .font(.system(size: 16, weight: .bold, design: .rounded))
                        .foregroundStyle(.white)
                        .lineLimit(1)
                }
                Spacer()
                Image(systemName: "chevron.right")
                    .foregroundStyle(.white.opacity(0.35))
            }
            .padding(.vertical, 6)
        }
        .buttonStyle(.plain)
    }
}

