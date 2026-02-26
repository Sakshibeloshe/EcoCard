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
    @EnvironmentObject var peerManager: PeerManager
    @EnvironmentObject var eventPeerManager: EventPeerManager

    @State private var search = ""
    @State private var filter = "All"
    @State private var showEventSheet = false
    @State private var selectedCard: CardModel?

    // Toast shown when a card is received via peer transfer
    @State private var receivedToastName: String? = nil

    private let filters = ["All", "Personal", "Business", "Social", "Event"]

    var filteredCards: [CardModel] {
        let base = store.myCards

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
        ZStack {
            Color.obsidianBlack.ignoresSafeArea()

            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 16) {

                    TopNavBar()
                        .padding(.horizontal, 16)

                    VStack(alignment: .leading, spacing: 4) {
                        Text("My Stack")
                            .font(.system(size: 34, weight: .heavy, design: .rounded))
                            .foregroundStyle(.white)

                        Text("Your digital identity")
                            .font(.system(size: 18, weight: .medium, design: .rounded))
                            .foregroundStyle(.white.opacity(0.35))
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 4)

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
                    .padding(.bottom, 120)
                }
                .padding(.top, 10)
            }

            // MARK: Received card toast
            if let name = receivedToastName {
                VStack {
                    Spacer()
                    HStack(spacing: 10) {
                        Image(systemName: "arrow.down.circle.fill")
                            .foregroundColor(.skyBlue)
                        Text("Card received from \(name)!")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(.white)
                    }
                    .padding(.horizontal, 20)
                    .padding(.vertical, 14)
                    .background(
                        Capsule()
                            .fill(Color.white.opacity(0.1))
                            .overlay(Capsule().stroke(Color.skyBlue.opacity(0.3), lineWidth: 1))
                    )
                    .shadow(color: .black.opacity(0.4), radius: 10)
                    .padding(.bottom, 110)
                    .transition(.move(edge: .bottom).combined(with: .opacity))
                }
            }
        }
        .onAppear {
            store.fetchMyCards()

            // Wire event peer manager callback to save received cards
            eventPeerManager.onCardReceived = { card in
                store.saveInboxCard(card)

                withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                    receivedToastName = card.fullName
                }

                Task {
                    try? await Task.sleep(nanoseconds: 3_000_000_000)
                    await MainActor.run {
                        withAnimation {
                            receivedToastName = nil
                        }
                    }
                }
            }
        }
        .sheet(isPresented: $showEventSheet) {
            EventModeSheet()
                .environmentObject(eventManager)
        }
        .fullScreenCover(item: $selectedCard) { card in
            ShareCardView(card: card)
        }
        // Auto-save received card from 1:1 peer transfer and show toast
        .onChange(of: peerManager.receivedCard) { card in
            guard let card else { return }

            store.saveInboxCard(card)

            withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                receivedToastName = card.fullName
            }

            peerManager.receivedCard = nil

            Task {
                try? await Task.sleep(nanoseconds: 3_000_000_000)
                await MainActor.run {
                    withAnimation {
                        receivedToastName = nil
                    }
                }
            }
        }
    }
}
