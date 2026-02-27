import SwiftUI

struct InboxView: View {
    @EnvironmentObject var store: AppStore
    @EnvironmentObject var eventManager: EventModeManager

    @State private var search = ""
    @State private var filter = "All"
    @State private var grouped = true
    @State private var folderSheetCard: CardModel?
    @State private var showEventSheet = false
    @State private var showCreateFolder = false
    @State private var newFolderName = ""

    private let filters = ["All", "Personal", "Business", "Social", "Event"]

    enum InboxItem: Identifiable {
        case folder(FolderModel)
        case card(CardModel)

        var id: String {
            switch self {
            case .folder(let f): return "folder-\(f.id.uuidString)"
            case .card(let c):   return "card-\(c.id.uuidString)"
            }
        }

        var sortName: String {
            switch self {
            case .folder(let f): return f.name.lowercased()
            case .card(let c):   return c.fullName.lowercased()
            }
        }
    }

    var mixedItems: [InboxItem] {
        let cards = store.inboxCards.filter { $0.folderId == nil }
        let typeFilteredCards: [CardModel] = {
            switch filter {
            case "Personal": return cards.filter { $0.type == .personal }
            case "Business": return cards.filter { $0.type == .business }
            case "Social":   return cards.filter { $0.type == .social }
            case "Event":    return cards.filter { $0.type == .event }
            default:         return cards
            }
        }()

        let searchedCards = typeFilteredCards.filter {
            search.isEmpty || $0.fullName.lowercased().contains(search.lowercased())
        }

        let folders = store.folders.filter {
            search.isEmpty || $0.name.lowercased().contains(search.lowercased())
        }

        let items = folders.map(InboxItem.folder) + searchedCards.map(InboxItem.card)
        return items.sorted { $0.sortName < $1.sortName }
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
                            HStack {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text("Connections")
                                        .font(.system(size: 34, weight: .heavy, design: .rounded))
                                        .foregroundStyle(.white)
                                    Text("Cards people shared with you")
                                        .font(.system(size: 16, weight: .medium, design: .rounded))
                                        .foregroundStyle(.white.opacity(0.35))
                                }
                                
                                Spacer()
                                
                                // New Folder Button
                                Button {
                                    newFolderName = ""
                                    showCreateFolder = true
                                } label: {
                                    Image(systemName: "folder.badge.plus")
                                        .font(.system(size: 18, weight: .bold))
                                        .foregroundStyle(.white.opacity(0.6))
                                        .frame(width: 44, height: 44)
                                        .background(Color.white.opacity(0.06))
                                        .clipShape(Circle())
                                }
                            }
                        }
                        .padding(.horizontal, 20)
                        .padding(.top, 4)


                        FilterPills(items: filters, selected: $filter)
                            .padding(.horizontal, 16)

                        SearchBar(text: $search, placeholder: "Search connections")
                            .padding(.horizontal, 16)
                            .padding(.top, 4)

                        if mixedItems.isEmpty {
                            emptyState.padding(.top, 60)
                        } else {
                            LazyVStack(spacing: 34) {
                                ForEach(mixedItems) { item in
                                    switch item {
                                    case .folder(let folder):
                                        NavigationLink {
                                            FolderDetailView(folder: folder)
                                        } label: {
                                            folderCard(folder: folder)
                                        }
                                        .buttonStyle(CardPressButtonStyle())
                                        .padding(.horizontal, 16)
                                        .contextMenu {
                                            Button(role: .destructive) {
                                                store.deleteFolder(id: folder.id)
                                                UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                                            } label: {
                                                Label("Delete Folder", systemImage: "trash")
                                            }
                                        }

                                    case .card(let card):
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
            .alert("New Folder", isPresented: $showCreateFolder) {
                TextField("Folder name", text: $newFolderName)
                    .autocorrectionDisabled()
                Button("Create") {
                    store.createFolder(name: newFolderName)
                    UIImpactFeedbackGenerator(style: .light).impactOccurred()
                }
                Button("Cancel", role: .cancel) { }
            } message: {
                Text("Give this folder a name")
            }
        }
    }

    private func folderCard(folder: FolderModel) -> some View {
        let count = store.inboxCards.filter { $0.folderId == folder.id }.count

        return ZStack(alignment: .bottomLeading) {
            // Background Gradient - Brighter and More Saturated
            RoundedRectangle(cornerRadius: 32, style: .continuous)
                .fill(
                    LinearGradient(
                        colors: [folder.color.opacity(0.6), folder.color.opacity(0.3)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .shadow(color: folder.color.opacity(0.2), radius: 20, x: 0, y: 10)

            // Folder Tab Accent
            VStack {
                HStack {
                    Spacer()
                    Path { path in
                        path.move(to: CGPoint(x: 0, y: 0))
                        path.addLine(to: CGPoint(x: 90, y: 0))
                        path.addLine(to: CGPoint(x: 80, y: 18))
                        path.addLine(to: CGPoint(x: 10, y: 18))
                        path.closeSubpath()
                    }
                    .fill(Color.white.opacity(0.25))
                    .frame(width: 90, height: 18)
                    .padding(.trailing, 32)
                }
                Spacer()
            }

            VStack(alignment: .leading, spacing: 8) {
                Text(folder.name)
                    .font(.system(size: 28, weight: .bold, design: .rounded))
                    .foregroundStyle(.white)

                Text("Cards: \(count)")
                    .font(.system(size: 15, weight: .bold, design: .rounded))
                    .foregroundStyle(.white.opacity(0.5))
            }
            .padding(32)
        }
        .aspectRatio(1.5, contentMode: .fit) // Matches Connection Cards
        .overlay(
            RoundedRectangle(cornerRadius: 32, style: .continuous)
                .stroke(Color.white.opacity(0.15), lineWidth: 1.5)
        )
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
