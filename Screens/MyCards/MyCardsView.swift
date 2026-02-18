//
//  MyCardsView.swift
//  BeforeUSayIt
//
//  Created by SDC-USER on 06/02/26.
//
import SwiftUI

struct MyCardsView: View {
    @EnvironmentObject var store: AppStore
    @EnvironmentObject var eventManager: EventModeManager
    
    @State private var search = ""
    @State private var filter = "All"
    @State private var showEventSheet = false
    @State private var selectedCard: CardModel?

    private let filters = ["All", "Personal", "Business", "Social", "Event"]

    var filteredCards: [CardModel] {
        let base = store.myCards

        let typeFiltered: [CardModel] = {
            switch filter {
            case "Personal": return base.filter { $0.type == .personal }
            case "Business": return base.filter { $0.type == .business }
            case "Social": return base.filter { $0.type == .social }
            case "Event": return base.filter { $0.type == .event }
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

                TopNavBar()
                    .padding(.horizontal, 16)
                
                Text("My Stack")
                    .font(.system(size: 54, weight: .heavy, design: .rounded))
                    .foregroundStyle(.white)
                    .padding(.horizontal, 16)
                    .padding(.top, 8)

                SearchBar(text: $search, placeholder: "Search cards")

                FilterPills(items: filters, selected: $filter)
                    .padding(.horizontal, 16)

                LazyVStack(spacing: 22) {
                    ForEach(filteredCards) { card in
                        Button {
                            selectedCard = card
                        } label: {
                            CardFrontView(card: card)
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.top, 12)
                .padding(.bottom, 120) // ensures floating tab bar doesn't overlap
            }
            .padding(.top, 10)
            .padding(.top, 10)
        }
        }
        .onAppear {
            store.fetchMyCards()
        }
        .sheet(isPresented: $showEventSheet) {
            EventModeSheet()
                .environmentObject(eventManager)
        }
        .fullScreenCover(item: $selectedCard) { card in
            ShareCardView(card: card)
        }
    }
}

