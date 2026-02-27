import SwiftUI
import PhotosUI

struct OnboardingView: View {
    @EnvironmentObject var store: AppStore
    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding = false

    @State private var page = 0

    // Card wizard state
    @State private var name = ""
    @State private var role = ""
    @State private var intent = ""
    @State private var selectedPhoto: PhotosPickerItem? = nil
    @State private var photoData: Data? = nil
    @State private var draftCard: CardModel? = nil
    @State private var showDeleteConfirm = false

    private let totalPages = 8 // 0=welcome, 1-3=slides, 4=name, 5=role, 6=photo+intent, 7=preview

    let roleQuickPicks = ["Designer", "Developer", "Founder", "Student", "Creator", "Manager"]

    // How-it-works slide content
    let slides: [(icon: String, color: Color, step: String, title: String, subtitle: String)] = [
        ("creditcard.fill",  Color(red:1.0, green:0.70, blue:0.75), "1 OF 3", "Create your card",       "Design your digital identity in seconds"),
        ("iphone",           Color(red:0.60, green:0.85, blue:0.95), "2 OF 3", "Tap phones together",     "NFC-powered instant sharing"),
        ("bolt.fill",        Color(red:0.78, green:0.95, blue:0.60), "3 OF 3", "Instantly connect",       "No screenshots. No typing."),
    ]

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()

            VStack {
                // SKIP button
                HStack {
                    Spacer()
                    if page < 7 {
                        Button("SKIP") {
                            buildDraftAndFinish()
                        }
                        .font(.system(size: 13, weight: .bold))
                        .foregroundStyle(.white.opacity(0.35))
                        .tracking(1.2)
                    }
                }
                .padding(.horizontal, 24)
                .padding(.top, 20)

                Spacer()

                // Page content
                Group {
                    switch page {
                    case 0:      welcomePage
                    case 1, 2, 3: howItWorksPage(index: page - 1)
                    case 4:      namePage
                    case 5:      rolePage
                    case 6:      photoIntentPage
                    case 7:      previewPage
                    default:     EmptyView()
                    }
                }
                .transition(.asymmetric(
                    insertion: .opacity.combined(with: .move(edge: .trailing)),
                    removal: .opacity.combined(with: .move(edge: .leading))
                ))

                Spacer()

                // Bottom bar: dots + button
                if page < 7 {
                    bottomBar
                }
            }
        }
    }

    // MARK: - Page 0: Welcome

    private var welcomePage: some View {
        VStack(spacing: 16) {
            ZStack {
                RoundedRectangle(cornerRadius: 28, style: .continuous)
                    .fill(Color.white.opacity(0.08))
                    .frame(width: 80, height: 80)
                Image(systemName: "rectangle.stack.fill")
                    .font(.system(size: 36, weight: .bold))
                    .foregroundStyle(.white)
            }
            .shadow(color: .white.opacity(0.08), radius: 20)

            VStack(spacing: 6) {
                Text("Simple.\nPowerful.")
                    .font(.system(size: 46, weight: .heavy, design: .rounded))
                    .foregroundStyle(.white)
                    .multilineTextAlignment(.center)

                Text("Digital cards that actually work.")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundStyle(.white.opacity(0.4))
                    .multilineTextAlignment(.center)
            }
        }
        .padding(.horizontal, 32)
    }

    // MARK: - Pages 1–3: How It Works

    private func howItWorksPage(index: Int) -> some View {
        let slide = slides[index]
        return VStack(spacing: 28) {
            Text("Simple.\nPowerful.")
                .font(.system(size: 36, weight: .heavy, design: .rounded))
                .foregroundStyle(.white)
                .multilineTextAlignment(.center)

            Text("HOW IT WORKS")
                .font(.system(size: 11, weight: .black))
                .foregroundStyle(.white.opacity(0.3))
                .tracking(2)

            ZStack {
                RoundedRectangle(cornerRadius: 28, style: .continuous)
                    .fill(slide.color.opacity(0.25))
                    .frame(width: 90, height: 90)
                    .shadow(color: slide.color.opacity(0.5), radius: 24)

                Image(systemName: slide.icon)
                    .font(.system(size: 38, weight: .bold))
                    .foregroundStyle(slide.color)
            }

            Text(slide.step)
                .font(.system(size: 11, weight: .black))
                .foregroundStyle(.white.opacity(0.3))
                .tracking(2)

            VStack(spacing: 6) {
                Text(slide.title)
                    .font(.system(size: 28, weight: .heavy, design: .rounded))
                    .foregroundStyle(.white)

                Text(slide.subtitle)
                    .font(.system(size: 15, weight: .medium))
                    .foregroundStyle(.white.opacity(0.45))
            }
            .multilineTextAlignment(.center)
        }
        .padding(.horizontal, 32)
    }

    // MARK: - Page 4: Name

    private var namePage: some View {
        VStack(alignment: .leading, spacing: 24) {
            ZStack {
                RoundedRectangle(cornerRadius: 22, style: .continuous)
                    .fill(Color(red:1.0, green:0.70, blue:0.75).opacity(0.25))
                    .frame(width: 60, height: 60)
                Image(systemName: "creditcard.fill")
                    .font(.system(size: 26, weight: .bold))
                    .foregroundStyle(Color(red:1.0, green:0.70, blue:0.75))
            }

            VStack(alignment: .leading, spacing: 6) {
                Text("Create your\nfirst card")
                    .font(.system(size: 36, weight: .heavy, design: .rounded))
                    .foregroundStyle(.white)

                Text("Let's start with your name")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundStyle(.white.opacity(0.4))
            }

            VStack(alignment: .leading, spacing: 8) {
                Text("YOUR NAME")
                    .font(.system(size: 11, weight: .black))
                    .foregroundStyle(.white.opacity(0.3))
                    .tracking(1.5)

                TextField("Emily Parker", text: $name)
                    .font(.system(size: 17, weight: .medium))
                    .foregroundStyle(.white)
                    .padding(16)
                    .background(Color.white.opacity(0.07))
                    .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                    .overlay(
                        RoundedRectangle(cornerRadius: 16, style: .continuous)
                            .stroke(Color.white.opacity(name.isEmpty ? 0.08 : 0.3), lineWidth: 1.5)
                    )
                    .autocorrectionDisabled()
            }
        }
        .padding(.horizontal, 28)
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    // MARK: - Page 5: Role

    private var rolePage: some View {
        VStack(alignment: .leading, spacing: 24) {
            ZStack {
                RoundedRectangle(cornerRadius: 22, style: .continuous)
                    .fill(Color(red:0.78, green:0.95, blue:0.60).opacity(0.25))
                    .frame(width: 60, height: 60)
                Image(systemName: "bolt.fill")
                    .font(.system(size: 26, weight: .bold))
                    .foregroundStyle(Color(red:0.78, green:0.95, blue:0.60))
            }

            VStack(alignment: .leading, spacing: 6) {
                Text("What do\nyou do?")
                    .font(.system(size: 36, weight: .heavy, design: .rounded))
                    .foregroundStyle(.white)

                Text("Your role or title")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundStyle(.white.opacity(0.4))
            }

            VStack(alignment: .leading, spacing: 8) {
                Text("ROLE / TITLE")
                    .font(.system(size: 11, weight: .black))
                    .foregroundStyle(.white.opacity(0.3))
                    .tracking(1.5)

                TextField("Product Designer", text: $role)
                    .font(.system(size: 17, weight: .medium))
                    .foregroundStyle(.white)
                    .padding(16)
                    .background(Color.white.opacity(0.07))
                    .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                    .overlay(
                        RoundedRectangle(cornerRadius: 16, style: .continuous)
                            .stroke(Color.white.opacity(role.isEmpty ? 0.08 : 0.3), lineWidth: 1.5)
                    )
                    .autocorrectionDisabled()
            }

            VStack(alignment: .leading, spacing: 10) {
                Text("QUICK PICKS")
                    .font(.system(size: 11, weight: .black))
                    .foregroundStyle(.white.opacity(0.3))
                    .tracking(1.5)

                FlowLayout(spacing: 10) {
                    ForEach(roleQuickPicks, id: \.self) { pick in
                        Button {
                            role = pick
                            UIImpactFeedbackGenerator(style: .light).impactOccurred()
                        } label: {
                            Text(pick)
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundStyle(role == pick ? .black : .white.opacity(0.7))
                                .padding(.horizontal, 16)
                                .padding(.vertical, 9)
                                .background(role == pick ? Color(red:0.78, green:0.95, blue:0.60) : Color.white.opacity(0.08))
                                .clipShape(Capsule())
                        }
                    }
                }
            }
        }
        .padding(.horizontal, 28)
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    // MARK: - Page 6: Photo + Intent

    private var photoIntentPage: some View {
        VStack(alignment: .leading, spacing: 24) {
            ZStack {
                RoundedRectangle(cornerRadius: 22, style: .continuous)
                    .fill(Color(red:0.60, green:0.85, blue:0.95).opacity(0.25))
                    .frame(width: 60, height: 60)
                Image(systemName: "person.crop.circle")
                    .font(.system(size: 26, weight: .bold))
                    .foregroundStyle(Color(red:0.60, green:0.85, blue:0.95))
            }

            VStack(alignment: .leading, spacing: 6) {
                Text("Almost\ndone!")
                    .font(.system(size: 36, weight: .heavy, design: .rounded))
                    .foregroundStyle(.white)

                Text("Add a photo and intent")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundStyle(.white.opacity(0.4))
            }

            // Photo picker
            PhotosPicker(selection: $selectedPhoto, matching: .images) {
                HStack(spacing: 14) {
                    ZStack {
                        Circle()
                            .fill(Color.white.opacity(0.08))
                            .frame(width: 56, height: 56)

                        if let data = photoData, let ui = UIImage(data: data) {
                            Image(uiImage: ui)
                                .resizable()
                                .scaledToFill()
                                .frame(width: 56, height: 56)
                                .clipShape(Circle())
                        } else {
                            Image(systemName: "person.crop.circle.badge.plus")
                                .font(.system(size: 22))
                                .foregroundStyle(.white.opacity(0.5))
                        }
                    }

                    Text(photoData == nil ? "Add Profile Photo" : "Change Photo")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundStyle(.white.opacity(0.8))

                    Spacer()
                    Image(systemName: "chevron.right")
                        .font(.system(size: 13, weight: .bold))
                        .foregroundStyle(.white.opacity(0.2))
                }
                .padding(16)
                .background(Color.white.opacity(0.06))
                .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .stroke(Color.white.opacity(0.08), lineWidth: 1)
                )
            }
            .onChange(of: selectedPhoto) { item in
                Task {
                    if let data = try? await item?.loadTransferable(type: Data.self) {
                        photoData = data
                    }
                }
            }

            VStack(alignment: .leading, spacing: 8) {
                Text("INTENT (OPTIONAL)")
                    .font(.system(size: 11, weight: .black))
                    .foregroundStyle(.white.opacity(0.3))
                    .tracking(1.5)

                TextField("e.g. Open to collab", text: $intent)
                    .font(.system(size: 17, weight: .medium))
                    .foregroundStyle(.white)
                    .padding(16)
                    .background(Color.white.opacity(0.07))
                    .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                    .overlay(
                        RoundedRectangle(cornerRadius: 16, style: .continuous)
                            .stroke(Color.white.opacity(0.08), lineWidth: 1.5)
                    )
                    .autocorrectionDisabled()
            }
        }
        .padding(.horizontal, 28)
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    // MARK: - Page 7: Preview

    private var previewPage: some View {
        VStack(spacing: 28) {
            VStack(spacing: 6) {
                Text("Your card\nis ready 🎉")
                    .font(.system(size: 36, weight: .heavy, design: .rounded))
                    .foregroundStyle(.white)
                    .multilineTextAlignment(.center)

                Text("Here's how it looks")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundStyle(.white.opacity(0.4))
            }

            if let card = draftCard {
                CardFrontView(card: card)
                    .shadow(color: card.theme.color.opacity(0.35), radius: 30, y: 14)
            }

            Button {
                if let card = draftCard {
                    store.addMyCard(card)
                }
                hasCompletedOnboarding = true
            } label: {
                HStack {
                    Text("Go to My Cards")
                        .font(.system(size: 17, weight: .bold, design: .rounded))
                    Image(systemName: "arrow.right")
                        .font(.system(size: 15, weight: .bold))
                }
                .foregroundStyle(.black)
                .frame(maxWidth: .infinity)
                .frame(height: 56)
                .background(Color(red:0.78, green:0.95, blue:0.60))
                .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
                .shadow(color: Color(red:0.78, green:0.95, blue:0.60).opacity(0.4), radius: 16, y: 8)
            }
            .padding(.horizontal, 28)
        }
    }

    // MARK: - Bottom Bar

    private var bottomBar: some View {
        VStack(spacing: 20) {
            // Page dots
            HStack(spacing: 8) {
                ForEach(0..<7) { i in
                    RoundedRectangle(cornerRadius: 3)
                        .fill(page == i ? Color.white : Color.white.opacity(0.2))
                        .frame(width: page == i ? 24 : 8, height: 6)
                        .animation(.spring(response: 0.35, dampingFraction: 0.7), value: page)
                }
            }

            // CONTINUE / NEXT button
            Button {
                advance()
            } label: {
                HStack {
                    Text(page < 3 ? "CONTINUE" : "NEXT")
                        .font(.system(size: 15, weight: .black))
                        .tracking(1.2)
                    Image(systemName: "chevron.right")
                        .font(.system(size: 13, weight: .black))
                }
                .foregroundStyle(nextButtonForeground)
                .frame(maxWidth: .infinity)
                .frame(height: 56)
                .background(nextButtonBackground)
                .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
            }
            .disabled(isNextDisabled)
            .padding(.horizontal, 28)
        }
        .padding(.bottom, 36)
    }

    // MARK: - Logic

    private var isNextDisabled: Bool {
        switch page {
        case 4: return name.trimmingCharacters(in: .whitespaces).isEmpty
        case 5: return role.trimmingCharacters(in: .whitespaces).isEmpty
        default: return false
        }
    }

    private var nextButtonForeground: Color {
        isNextDisabled ? .white.opacity(0.2) : .black
    }

    private var nextButtonBackground: Color {
        if isNextDisabled { return Color.white.opacity(0.06) }
        switch page {
        case 4: return Color(red:1.0, green:0.70, blue:0.75)
        case 5: return Color(red:0.78, green:0.95, blue:0.60)
        case 6: return Color(red:0.60, green:0.85, blue:0.95)
        default: return Color.white
        }
    }

    private func advance() {
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
        if page == 6 {
            buildDraft()
        }
        withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
            page = min(page + 1, totalPages - 1)
        }
    }

    private func buildDraft() {
        draftCard = CardModel(
            type: .personal,
            theme: .pink,
            fullName: name.trimmingCharacters(in: .whitespaces),
            title: role.trimmingCharacters(in: .whitespaces),
            intent: intent.isEmpty ? nil : intent
        )
    }

    private func buildDraftAndFinish() {
        let trimmedName = name.trimmingCharacters(in: .whitespaces)
        if !trimmedName.isEmpty {
            let card = CardModel(
                type: .personal,
                theme: .pink,
                fullName: trimmedName,
                title: role.trimmingCharacters(in: .whitespaces),
                intent: intent.isEmpty ? nil : intent
            )
            store.addMyCard(card)
        }
        hasCompletedOnboarding = true
    }
}

// MARK: - Simple Flow Layout for Quick Picks

struct FlowLayout: Layout {
    var spacing: CGFloat = 8

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let maxWidth = proposal.width ?? 0
        var x: CGFloat = 0
        var y: CGFloat = 0
        var rowHeight: CGFloat = 0

        for subview in subviews {
            let size = subview.sizeThatFits(.unspecified)
            if x + size.width > maxWidth && x > 0 {
                x = 0
                y += rowHeight + spacing
                rowHeight = 0
            }
            x += size.width + spacing
            rowHeight = max(rowHeight, size.height)
        }
        return CGSize(width: maxWidth, height: y + rowHeight)
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        var x = bounds.minX
        var y = bounds.minY
        var rowHeight: CGFloat = 0

        for subview in subviews {
            let size = subview.sizeThatFits(.unspecified)
            if x + size.width > bounds.maxX && x > bounds.minX {
                x = bounds.minX
                y += rowHeight + spacing
                rowHeight = 0
            }
            subview.place(at: CGPoint(x: x, y: y), proposal: .unspecified)
            x += size.width + spacing
            rowHeight = max(rowHeight, size.height)
        }
    }
}
