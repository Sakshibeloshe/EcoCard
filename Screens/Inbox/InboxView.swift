//
//  InboxView.swift
//  BeforeUSayIt
//
//  Created by SDC-USER on 06/02/26.
//
import SwiftUI

struct InboxView: View {
    @EnvironmentObject var store: AppStore
    @EnvironmentObject var eventManager: EventModeManager
    
    @State private var search = ""
    @State private var filter = "All"
    @State private var grouped = true
    @State private var folderSheetCard: CardModel?
    @State private var showEventSheet = false

    private let filters = ["All", "Personal", "Business", "Social", "Event", "Custom"]

    var filtered: [CardModel] {
        let base = store.inboxCards

        let typeFiltered: [CardModel] = {
            switch filter {
            case "Personal": return base.filter { $0.type == .personal }
            case "Business": return base.filter { $0.type == .business }
            case "Social": return base.filter { $0.type == .social }
            case "Event": return base.filter { $0.type == .event }
            case "Custom": return base.filter { $0.type == .blank }
            default: return base
            }
        }()

        if search.isEmpty { return typeFiltered }
        return typeFiltered.filter { $0.fullName.lowercased().contains(search.lowercased()) }
    }

    var body: some View {
        ZStack {
            Color.obsidianBlack.ignoresSafeArea()
            
            ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: 16) {

                TopNavBar(eventManager: eventManager, showEventSheet: $showEventSheet)
                    .padding(.horizontal, 16)

                SearchBar(text: $search, placeholder: "Search connections")
                    .padding(.horizontal, 16)
                    .padding(.top, 8)

                HStack(spacing: 10) {
                    Button {
                        grouped.toggle()
                        UIImpactFeedbackGenerator(style: .light).impactOccurred()
                    } label: {
                        HStack(spacing: 8) {
                            Image(systemName: "square.grid.2x2.fill")
                            Text("Grouped")
                        }
                        .font(.system(size: 14, weight: .bold, design: .rounded))
                        .foregroundStyle(grouped ? .black : .white.opacity(0.35))
                        .padding(.horizontal, 16)
                        .padding(.vertical, 10)
                        .background(grouped ? Color.softRose : Color.white.opacity(0.06))
                        .clipShape(Capsule())
                    }

                    FilterPills(items: filters, selected: $filter)
                }
                .padding(.horizontal, 16)

                FolderListView()

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
                            .buttonStyle(.plain)
                            .padding(.horizontal, 16)

                            VStack(alignment: .leading, spacing: 12) {
                                HStack(alignment: .top) {
                                    VStack(alignment: .leading, spacing: 2) {
                                        Text(card.fullName)
                                            .font(.system(size: 18, weight: .bold, design: .rounded))
                                            .foregroundStyle(.white)
                                        
                                        Text(card.title.uppercased())
                                            .font(.system(size: 12, weight: .bold, design: .rounded))
                                            .foregroundStyle(.white.opacity(0.4))
                                    }
                                    
                                    Spacer()
                                    
                                    Button {
                                        store.toggleFavorite(card)
                                    } label: {
                                        Image(systemName: card.isFavorite ? "star.fill" : "star")
                                            .foregroundStyle(card.isFavorite ? .yellow : .white.opacity(0.15))
                                            .font(.system(size: 18))
                                    }
                                }
                                .padding(.top, 4)

                                HStack {
                                    Button {
                                        folderSheetCard = card
                                    } label: {
                                        Text("Add to Folder")
                                            .font(.system(size: 14, weight: .bold, design: .rounded))
                                            .foregroundStyle(.white.opacity(0.4))
                                    }

                                    Spacer()

                                    if let event = card.eventName {
                                        Text("Met at \(event.lowercased())")
                                            .font(.system(size: 14, weight: .medium, design: .rounded))
                                            .foregroundStyle(.white.opacity(0.25))
                                    } else if !card.note.isEmpty {
                                        Text(card.note)
                                            .font(.system(size: 14, weight: .medium, design: .rounded))
                                            .foregroundStyle(.white.opacity(0.25))
                                    }
                                }
                            }
                            .padding(.horizontal, 20)
                        }
                    }
                }
                .padding(.top, 10)

                Spacer(minLength: 120)
            }
            .padding(.top, 10)
        }
        }
        .sheet(item: $folderSheetCard) { card in
            FolderPickerSheet(card: card)
        }
        .sheet(isPresented: $showEventSheet) {
            EventModeSheet()
                .environmentObject(eventManager)
        }
    }
}

