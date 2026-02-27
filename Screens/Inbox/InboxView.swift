import SwiftUI

struct InboxView: View {
    @EnvironmentObject var store: AppStore
    @EnvironmentObject var eventManager: EventModeManager

    @State private var search = ""
    @State private var filter = "All"
    @State private var grouped = true
    @State private var folderSheetCard: CardModel?
    @State private var showEventSheet = false

    private let filters = ["All", "Personal", "Business", "Social", "Event"]

    var filtered: [CardModel] {
        let base = store.inboxCards
        let typeFiltered: [CardModel] = {
            switch filter {
            case "Personal": return base.filter { $0.type == .personal }
            case "Business": return base.filter { $0.type == .business }
            case "Social":   return base.filter { $0.type == .social }
            case "Event":    return base.filter { $0.type == .event }
            default:         return base
            }
        }()
        if search.isEmpty { return typeFiltered }
        return typeFiltered.filter { $0.fullName.lowercased().contains(search.lowercased()) }
    }

    var body: some View {
        NavigationStack {
            ZStack {
                Color.obsidianBlack.ignoresSafeArea()

                ScrollView(showsIndicators: false) {
                    VStack(alignment: .leading, spacing: 16) {

                        TopNavBar()
                            .padding(.horizontal, 16)

                        // Header
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Connections")
                                .font(.system(size: 34, weight: .heavy, design: .rounded))
                                .foregroundStyle(.white)
                            Text("Cards people shared with you")
                                .font(.system(size: 18, weight: .medium, design: .rounded))
                                .foregroundStyle(.white.opacity(0.35))
                        }
                        .padding(.horizontal, 20)
                        .padding(.top, 4)

                        // Folders section
                        if !store.folders.isEmpty {
                            VStack(alignment: .leading, spacing: 10) {
                                Text("MY FOLDERS")
                                    .font(.system(size: 11, weight: .black))
                                    .foregroundStyle(.white.opacity(0.3))
                                    .tracking(1.5)
                                    .padding(.horizontal, 20)

                                FolderListView()
                            }
                        }

                        FilterPills(items: filters, selected: $filter)
                            .padding(.horizontal, 16)

                        SearchBar(text: $search, placeholder: "Search connections")
                            .padding(.horizontal, 16)
                            .padding(.top, 4)

                        if filtered.isEmpty {
                            emptyState.padding(.top, 60)
                        } else {
                            VStack(spacing: 34) {
                                ForEach(filtered) { card in
                                    VStack(alignment: .leading, spacing: 14) {

                                        if let event = card.eventName, grouped {
                                            HStack(spacing: 12) {
                                                Text(event.uppercased())
                                                    .font(.system(size: 13, weight: .bold, design: .rounded))
                                                    .foregroundStyle(.white.opacity(0.4))
                                                    .tracking(2)
                                                Rectangle()
                                                    .fill(Color.white.opacity(0.1))
                                                    .frame(height: 1)
                                            }
                                            .padding(.horizontal, 16)
                                        }

                                        NavigationLink {
                                            CardDetailView(card: card)
                                        } label: {
                                            CardFrontView(card: card)
                                        }
                                        .buttonStyle(CardPressButtonStyle())
                                        .padding(.horizontal, 16)

                                        VStack(alignment: .leading, spacing: 12) {
                                            HStack(alignment: .top) {
                                                VStack(alignment: .leading, spacing: 2) {
                                                    Text(card.fullName)
                                                        .font(.system(size: 18, weight: .bold, design: .rounded))
                                                        .foregroundStyle(.white)
                                                    Text(card.title.uppercased())
                                                        .font(.system(size: 11, weight: .semibold, design: .rounded))
                                                        .foregroundStyle(.white.opacity(0.4))
                                                        .tracking(0.8)
                                                }
                                                Spacer()
                                                Button {
                                                    withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                                                        store.toggleFavorite(card)
                                                    }
                                                    UIImpactFeedbackGenerator(style: .light).impactOccurred()
                                                } label: {
                                                    Image(systemName: card.isFavorite ? "star.fill" : "star")
                                                        .foregroundStyle(card.isFavorite ? .yellow : .white.opacity(0.15))
                                                        .font(.system(size: 18))
                                                        .scaleEffect(card.isFavorite ? 1.15 : 1.0)
                                                        .animation(.spring(response: 0.25, dampingFraction: 0.5), value: card.isFavorite)
                                                }
                                            }
                                            .padding(.top, 4)

                                            HStack {
                                                Button {
                                                    folderSheetCard = card
                                                } label: {
                                                    HStack(spacing: 5) {
                                                        Image(systemName: card.folderId != nil ? "folder.fill" : "folder.badge.plus")
                                                            .font(.system(size: 12))
                                                        Text(card.folderId != nil
                                                             ? (store.folders.first(where: { $0.id == card.folderId })?.name ?? "Folder")
                                                             : "Add to Folder")
                                                    }
                                                    .font(.system(size: 13, weight: .bold, design: .rounded))
                                                    .foregroundStyle(card.folderId != nil ? .white.opacity(0.6) : .white.opacity(0.3))
                                                }
                                                Spacer()
                                                if let event = card.eventName {
                                                    Text("Met at \(event.lowercased())")
                                                        .font(.system(size: 13, weight: .medium, design: .rounded))
                                                        .foregroundStyle(.white.opacity(0.25))
                                                } else if !card.note.isEmpty {
                                                    Text(card.note)
                                                        .font(.system(size: 13, weight: .medium, design: .rounded))
                                                        .foregroundStyle(.white.opacity(0.25))
                                                }
                                            }
                                        }
                                        .padding(.horizontal, 20)
                                    }
                                    // Swipe to favorite
                                    .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                                        Button {
                                            withAnimation(.spring()) { store.toggleFavorite(card) }
                                            UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                                        } label: {
                                            Label(card.isFavorite ? "Unfavorite" : "Favorite",
                                                  systemImage: card.isFavorite ? "star.slash.fill" : "star.fill")
                                        }
                                        .tint(card.isFavorite ? .gray : .yellow)
                                    }
                                }
                            }
                            .padding(.top, 10)
                        }

                        Spacer(minLength: 120)
                    }
                    .padding(.top, 10)
                }
            }
            .sheet(item: $folderSheetCard) { card in
                FolderPickerSheet(card: card)
            }
            .sheet(isPresented: $showEventSheet) {
                EventModeSheet().environmentObject(eventManager)
            }
        }
    }

    private var emptyState: some View {
        VStack(spacing: 20) {
            ZStack {
                Circle()
                    .fill(Color.white.opacity(0.04))
                    .frame(width: 100, height: 100)
                Image(systemName: "person.2.slash")
                    .font(.system(size: 40, weight: .light))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [Color.skyBlue.opacity(0.7), Color.softRose.opacity(0.7)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
            }
            VStack(spacing: 6) {
                Text("No Connections Yet")
                    .font(.system(size: 22, weight: .bold, design: .rounded))
                    .foregroundStyle(.white)
                Text("Cards shared with you will\nappear here")
                    .font(.system(size: 15, weight: .medium, design: .rounded))
                    .foregroundStyle(.white.opacity(0.35))
                    .multilineTextAlignment(.center)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 20)
    }
}
