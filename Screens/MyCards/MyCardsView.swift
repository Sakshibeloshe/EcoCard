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
    @EnvironmentObject var eventPeerManager: EventModePeerManager

    @State private var search = ""
    @State private var filter = "All"
    @State private var showEventSheet = false
    @State private var selectedCard: CardModel?
    @State private var showEventSelection = false

    // Toast shown when a card is received
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
                    
                    if eventPeerManager.isActive {
                        eventModeBanner
                    }

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
                    
                    // Event Mode Entry
                    if !eventPeerManager.isActive {
                        eventModeEntry
                            .padding(.horizontal, 20)
                    }

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
        }
        .sheet(isPresented: $showEventSheet) {
            EventModeSheet()
                .environmentObject(eventManager)
                .environmentObject(eventPeerManager)
        }
        .fullScreenCover(item: $selectedCard) { card in
            ShareCardView(card: card)
        }
        // Auto-save received card and show toast
        .onChange(of: peerManager.receivedCard) { _, card in
            handleReceived(card)
            peerManager.receivedCard = nil
        }
        // Handle Event Mode received cards
        .onChange(of: eventPeerManager.receivedCards) { _, cards in
            if let latest = cards.last {
                handleReceived(latest)
            }
        }
    }
    
    // MARK: - Event Components
    
    private var eventModeBanner: some View {
        Button {
            showEventSheet = true
        } label: {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text("EVENT LIVE: \(eventManager.eventName.isEmpty ? "MESH ACTIVE" : eventManager.eventName.uppercased())")
                        .font(.system(size: 10, weight: .black))
                        .tracking(1.5)
                    Text("\(eventPeerManager.connectedPeerCount) people connected • \(eventPeerManager.receivedCards.count) cards received")
                        .font(.system(size: 12, weight: .bold))
                        .opacity(0.7)
                }
                Spacer()
                Image(systemName: "bolt.fill")
                    .font(.system(size: 20))
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 14)
            .background(Color.softRose)
            .foregroundColor(.black)
            .cornerRadius(16)
            .padding(.horizontal, 16)
            .transition(.move(edge: .top).combined(with: .opacity))
        }
        .buttonStyle(.plain)
    }
    
    private var eventModeEntry: some View {
        Button {
            showEventSheet = true
        } label: {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Start Event Session")
                        .font(.system(size: 16, weight: .bold, design: .rounded))
                        .foregroundColor(.white)
                    Text("Share card with everyone at once")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(.white.opacity(0.4))
                }
                Spacer()
                Image(systemName: "chevron.right")
                    .foregroundColor(.white.opacity(0.2))
            }
            .padding(20)
            .background(Color.white.opacity(0.05))
            .cornerRadius(20)
            .overlay(
                RoundedRectangle(cornerRadius: 20)
                    .stroke(Color.white.opacity(0.05), lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
    }
    
    private func handleReceived(_ card: CardModel?) {
        guard let card else { return }
        
        // Add event context if applicable
        var mutated = card
        if eventPeerManager.isActive {
            mutated.eventName = eventManager.eventName
            mutated.tags.append("Event")
        }
        
        store.saveInboxCardIfNew(mutated)
        
        withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
            receivedToastName = card.fullName
        }
        
        Task { @MainActor in
            try? await Task.sleep(nanoseconds: 3_000_000_000)
            withAnimation {
                if receivedToastName == card.fullName {
                    receivedToastName = nil
                }
            }
        }
    }
}
}
