import Foundation
import MultipeerConnectivity
import UIKit

// MARK: - Event Mode Peer Manager
//
// Manages a multi-peer "Event Mode" session where every participant:
//   1. Advertises their presence with the shared eventCode in discoveryInfo
//   2. Auto-connects to every peer advertising the same eventCode
//   3. Sends their own card when any peer connects
//   4. Flood-once: rebroadcasts newly-received cards to all OTHER peers
//      so even peers not directly connected get every card.
//
// Thread Model (Swift 6):
//   • MC delegate callbacks are nonisolated (arbitrary threads).
//   • All @Published mutations go through `updateUI { }` → MainActor.
//   • `session`, `myPeerID` are nonisolated(unsafe) constants whose
//     thread-safety is managed by MultipeerConnectivity.

final class EventModePeerManager: NSObject, ObservableObject {

    // MARK: - Published State (MainActor only)

    @Published var isActive: Bool = false
    @Published var connectedPeerCount: Int = 0
    @Published var receivedCards: [CardModel] = []   // unique cards received this session
    @Published var statusLabel: String = "Idle"
    @Published var eventCode: String = ""

    // MARK: - MC Internals

    private let serviceType = "ecocard-evnt"         // keep ≤15 chars, unique from p2p

    nonisolated(unsafe) private var session: MCSession?
    nonisolated(unsafe) private let myPeerID: MCPeerID

    private var advertiser: MCNearbyServiceAdvertiser?
    private var browser: MCNearbyServiceBrowser?

    // Flood-once tracking
    nonisolated(unsafe) private var seenCardIDs: Set<UUID> = []

    // The card this device will broadcast
    nonisolated(unsafe) private var myCard: CardModel?

    // MARK: - Init

    override init() {
        let name = UIDevice.current.name
        myPeerID = MCPeerID(displayName: name.isEmpty ? "EcoCard User" : name)
        super.init()
    }

    // MARK: - Start / Stop

    /// Begin an event session. Call from MainActor / SwiftUI.
    func startSession(eventCode: String, myCard: CardModel) {
        guard !isActive else { return }

        self.myCard = myCard
        self.eventCode = eventCode
        seenCardIDs = []

        // Create a fresh session for each event
        let s = MCSession(peer: myPeerID,
                          securityIdentity: nil,
                          encryptionPreference: .required)
        s.delegate = self
        session = s

        // Advertiser — broadcasts eventCode so matching peers can filter
        let adv = MCNearbyServiceAdvertiser(
            peer: myPeerID,
            discoveryInfo: ["eventCode": eventCode],
            serviceType: serviceType
        )
        adv.delegate = self
        adv.startAdvertisingPeer()
        advertiser = adv

        // Browser — keeps running the whole session to mesh-connect new arrivals
        let b = MCNearbyServiceBrowser(peer: myPeerID, serviceType: serviceType)
        b.delegate = self
        b.startBrowsingForPeers()
        browser = b

        isActive = true
        statusLabel = "Waiting for peers…"
        print("[EventMode] 🚀 Session started — code: \(eventCode)")
    }

    /// Tear down the event session. Call from MainActor / SwiftUI.
    func stopSession() {
        advertiser?.stopAdvertisingPeer()
        advertiser = nil
        browser?.stopBrowsingForPeers()
        browser = nil
        session?.disconnect()
        session = nil
        myCard = nil
        seenCardIDs = []
        isActive = false
        connectedPeerCount = 0
        receivedCards = []
        statusLabel = "Session ended"
        eventCode = ""
        print("[EventMode] 🛑 Session stopped")
    }

    // MARK: - Card Sending

    /// Broadcast my card to all currently connected peers.
    private func sendMyCard() {
        guard let session, let card = myCard,
              !session.connectedPeers.isEmpty else { return }
        sendCard(card, toPeers: session.connectedPeers, from: nil)
        print("[EventMode] 📤 Sent my card to \(session.connectedPeers.count) peer(s)")
    }

    /// Rebroadcast a received card to all peers EXCEPT the original sender.
    private func rebroadcast(_ card: CardModel, excluding sourcePeer: MCPeerID) {
        guard let session else { return }
        let targets = session.connectedPeers.filter { $0 != sourcePeer }
        guard !targets.isEmpty else { return }
        sendCard(card, toPeers: targets, from: sourcePeer)
        print("[EventMode] 🔁 Rebroadcasting \(card.fullName) to \(targets.count) peer(s)")
    }

    private func sendCard(_ card: CardModel, toPeers peers: [MCPeerID], from _: MCPeerID?) {
        guard let session else { return }
        do {
            let data = try JSONEncoder().encode(card)
            // .unreliable is fine for small card JSON — faster in crowded mesh
            try session.send(data, toPeers: peers, with: .reliable)
        } catch {
            print("[EventMode] ❌ Send error: \(error)")
        }
    }

    // MARK: - Private helpers

    private func updateUI(_ work: @escaping @MainActor @Sendable () -> Void) {
        Task { @MainActor in work() }
    }
}

// MARK: - MCSessionDelegate

extension EventModePeerManager: MCSessionDelegate {

    func session(_ session: MCSession,
                 peer peerID: MCPeerID,
                 didChange state: MCSessionState) {

        let count = session.connectedPeers.count
        let label: String

        switch state {
        case .connected:
            label = "\(count) peer\(count == 1 ? "" : "s") connected"
            // Send our card to the entire mesh whenever someone new joins
            sendMyCard()

        case .connecting:
            label = "Connecting to \(peerID.displayName)…"

        case .notConnected:
            label = count > 0
                ? "\(count) peer\(count == 1 ? "" : "s") connected"
                : "Looking for peers…"

        @unknown default:
            label = ""
        }

        print("[EventMode] 🔵 \(peerID.displayName) → \(state.rawValue)  peers=\(count)")

        updateUI {
            self.connectedPeerCount = count
            if !label.isEmpty { self.statusLabel = label }
        }
    }

    func session(_ session: MCSession,
                 didReceive data: Data,
                 fromPeer peerID: MCPeerID) {

        guard var card = try? JSONDecoder().decode(CardModel.self, from: data) else {
            print("[EventMode] ⚠️ Could not decode card data"); return
        }
        card.isReceived = true

        // Flood-once deduplication
        guard !seenCardIDs.contains(card.id) else {
            print("[EventMode] 🔄 Duplicate card \(card.fullName) — ignored")
            return
        }
        seenCardIDs.insert(card.id)

        // Rebroadcast BEFORE touching UI (reduces latency)
        rebroadcast(card, excluding: peerID)

        let receivedCard = card
        updateUI {
            self.receivedCards.append(receivedCard)
            self.statusLabel = "Got \(self.receivedCards.count) card\(self.receivedCards.count == 1 ? "" : "s")"
            print("[EventMode] 📥 Received: \(receivedCard.fullName)")
        }
    }

    // Required stubs
    func session(_: MCSession, didReceive _: InputStream,
                 withName _: String, fromPeer _: MCPeerID) {}
    func session(_: MCSession, didStartReceivingResourceWithName _: String,
                 fromPeer _: MCPeerID, with _: Progress) {}
    func session(_: MCSession, didFinishReceivingResourceWithName _: String,
                 fromPeer _: MCPeerID, at _: URL?, withError _: Error?) {}
}

// MARK: - MCNearbyServiceAdvertiserDelegate

extension EventModePeerManager: MCNearbyServiceAdvertiserDelegate {

    func advertiser(_ advertiser: MCNearbyServiceAdvertiser,
                    didReceiveInvitationFromPeer peerID: MCPeerID,
                    withContext _: Data?,
                    invitationHandler: @escaping (Bool, MCSession?) -> Void) {
        print("[EventMode] 📨 Accepting invite from \(peerID.displayName)")
        // Accept unconditionally — browser already filtered by eventCode
        invitationHandler(true, session)
    }

    func advertiser(_: MCNearbyServiceAdvertiser,
                    didNotStartAdvertisingPeer error: Error) {
        print("[EventMode] ❌ Advertiser error: \(error)")
    }
}

// MARK: - MCNearbyServiceBrowserDelegate

extension EventModePeerManager: MCNearbyServiceBrowserDelegate {

    func browser(_ browser: MCNearbyServiceBrowser,
                 foundPeer peerID: MCPeerID,
                 withDiscoveryInfo info: [String: String]?) {

        // 🔑 Key filter: only connect peers in the same event
        guard info?["eventCode"] == eventCode else {
            print("[EventMode] 🚫 Ignored \(peerID.displayName) — wrong event code")
            return
        }

        // Avoid re-inviting already-connected peers
        if let session, session.connectedPeers.contains(peerID) { return }

        print("[EventMode] 👀 Found matching peer \(peerID.displayName) — inviting")
        browser.invitePeer(peerID, to: session!, withContext: nil, timeout: 10)
    }

    func browser(_: MCNearbyServiceBrowser, lostPeer peerID: MCPeerID) {
        print("[EventMode] 👋 Lost peer \(peerID.displayName)")
    }

    func browser(_: MCNearbyServiceBrowser,
                 didNotStartBrowsingForPeers error: Error) {
        print("[EventMode] ❌ Browser error: \(error)")
    }
}
