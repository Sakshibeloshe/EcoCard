@preconcurrency import MultipeerConnectivity
import Foundation
import UIKit

/// Manages event-mode group card exchange via MultipeerConnectivity.
///
/// Simulates a "room" by encoding the event code in `discoveryInfo`.
/// Uses flood-once rebroadcast to guarantee full-mesh card delivery
/// even when not all peers are directly connected.
///
/// **Thread model (Swift 6)**: same pattern as `PeerManager` —
/// `@MainActor` class with `nonisolated` MC delegate methods that
/// hop back to the main actor via Task.
@MainActor
final class EventPeerManager: NSObject, ObservableObject, @unchecked Sendable {
    
    struct EventPacket: Codable {
        enum PacketType: String, Codable {
            case card
            case sessionEnded
        }
        let type: PacketType
        let card: CardModel?
    }

    // MARK: - Published State

    @Published var isActive: Bool = false
    @Published var connectedPeerCount: Int = 0
    @Published var receivedCards: [CardModel] = []
    @Published var connectedPeers: [String] = []
    @Published var statusLabel: String = "Idle"
    
    var onSessionEnded: (() -> Void)?

    // MARK: - MC Objects

    private let serviceType = "ecocard-evt"   // ≤15 chars, lowercase + hyphen

    nonisolated(unsafe) private let myPeerID: MCPeerID
    nonisolated(unsafe) private let session: MCSession

    private var advertiser: MCNearbyServiceAdvertiser?
    private var browser: MCNearbyServiceBrowser?

    // MARK: - Event State

    /// The code that defines the "room". Set before calling `start(...)`.
    private var eventCode: String = ""

    /// Thread-safe copy for the nonisolated browser delegate.
    /// Set once in `start()`, cleared in `stop()`. Read-only outside main actor.
    nonisolated(unsafe) private var _eventCodeForBrowser: String = ""

    /// The card this device broadcasts to every connected peer.
    private var myCard: CardModel?

    /// Tracks card IDs we have already seen to prevent duplicates and
    /// limit rebroadcast to exactly once per card.
    private var seenCardIDs: Set<UUID> = []

    /// Callback invoked on main actor when a new (non-duplicate) card arrives.
    var onCardReceived: ((CardModel) -> Void)?

    // MARK: - Init

    override init() {
        let name = UIDevice.current.name
        myPeerID = MCPeerID(displayName: name.isEmpty ? "EcoCard User" : name)
        session  = MCSession(peer: myPeerID,
                             securityIdentity: nil,
                             encryptionPreference: .required)
        super.init()
        session.delegate = self
    }

    // MARK: - Start / Stop

    /// Begin advertising and browsing with the given event code.
    func start(eventCode: String, card: CardModel) {
        guard !isActive else { return }

        self.eventCode = eventCode
        self._eventCodeForBrowser = eventCode
        self.myCard = card
        seenCardIDs = [card.id]   // pre-seed with own card to skip self-echo
        receivedCards = []

        // Advertiser — include event code in discoveryInfo
        let adv = MCNearbyServiceAdvertiser(
            peer: myPeerID,
            discoveryInfo: ["eventCode": eventCode],
            serviceType: serviceType
        )
        adv.delegate = self
        adv.startAdvertisingPeer()
        advertiser = adv

        // Browser
        let b = MCNearbyServiceBrowser(peer: myPeerID, serviceType: serviceType)
        b.delegate = self
        b.startBrowsingForPeers()
        browser = b

        isActive = true
        statusLabel = "Waiting for peers…"
        print("[EventPeerManager] 🚀 Started — code: \(eventCode)")
    }

    func stop() {
        advertiser?.stopAdvertisingPeer()
        advertiser = nil
        browser?.stopBrowsingForPeers()
        browser = nil
        session.disconnect()

        isActive = false
        connectedPeerCount = 0
        statusLabel = "Idle"
        eventCode = ""
        _eventCodeForBrowser = ""
        myCard = nil
        seenCardIDs = []
        connectedPeers = []
        print("[EventPeerManager] ⏹ Stopped")
    }

    // MARK: - Send Helpers

    /// Broadcast own card to ALL connected peers.
    private func broadcastMyCard() {
        guard let card = myCard, !session.connectedPeers.isEmpty else { return }

        let peers = session.connectedPeers
        let session = self.session
        let packet = EventPacket(type: .card, card: card)

        DispatchQueue.global(qos: .userInitiated).async {
            guard let data = try? JSONEncoder().encode(packet) else { return }
            try? session.send(data, toPeers: peers, with: .reliable)
            print("[EventPeerManager] 📤 Broadcast card packet to \(peers.count) peer(s)")
        }
    }

    /// Notify all participants that the host is ending the session.
    func sendTerminationSignal() {
        guard !session.connectedPeers.isEmpty else { return }
        let peers = session.connectedPeers
        let session = self.session
        let packet = EventPacket(type: .sessionEnded, card: nil)

        DispatchQueue.global(qos: .userInitiated).async {
            guard let data = try? JSONEncoder().encode(packet) else { return }
            try? session.send(data, toPeers: peers, with: .reliable)
            print("[EventPeerManager] 📢 Sent termination signal to \(peers.count) peer(s)")
        }
    }

    /// Rebroadcast a received card to all peers except the one who sent it.
    nonisolated private func rebroadcast(_ data: Data, excluding sender: MCPeerID) {
        let peers = session.connectedPeers.filter { $0 != sender }
        guard !peers.isEmpty else { return }
        try? session.send(data, toPeers: peers, with: .reliable)
        print("[EventPeerManager] 🔁 Rebroadcast to \(peers.count) peer(s)")
    }
}

// MARK: - MCSessionDelegate

extension EventPeerManager: MCSessionDelegate {

    nonisolated func session(_ session: MCSession,
                             peer peerID: MCPeerID,
                             didChange state: MCSessionState) {

        let count = session.connectedPeers.count
        let peerName = peerID.displayName

        Task { @MainActor [weak self] in
            guard let self else { return }
            self.connectedPeerCount = count
            self.connectedPeers = session.connectedPeers.map { $0.displayName }

            switch state {
            case .connected:
                self.statusLabel = "\(count) peer\(count == 1 ? "" : "s") connected"
                print("[EventPeerManager] 🔵 \(peerName) connected (total: \(count))")
                // Auto-send own card to ALL peers when a new peer joins
                self.broadcastMyCard()

            case .connecting:
                print("[EventPeerManager] 🟡 \(peerName) connecting…")

            case .notConnected:
                self.statusLabel = count > 0
                    ? "\(count) peer\(count == 1 ? "" : "s") connected"
                    : "Waiting for peers…"
                print("[EventPeerManager] 🔴 \(peerName) disconnected (total: \(count))")

            @unknown default:
                break
            }
        }
    }

    nonisolated func session(_ session: MCSession,
                             didReceive data: Data,
                             fromPeer peerID: MCPeerID) {

        guard let packet = try? JSONDecoder().decode(EventPacket.self, from: data) else {
            print("[EventPeerManager] ⚠️ Could not decode received packet")
            // Fallback for older card-only data if necessary, but we updated all senders.
            return
        }

        switch packet.type {
        case .card:
            guard let card = packet.card else { return }
            let cardID = card.id
            let senderName = peerID.displayName
            rebroadcast(data, excluding: peerID)

            Task { @MainActor [weak self] in
                guard let self else { return }
                guard !self.seenCardIDs.contains(cardID) else { return }
                self.seenCardIDs.insert(cardID)
                self.receivedCards.append(card)
                self.onCardReceived?(card)
                print("[EventPeerManager] 📥 New card from \(senderName): \(card.fullName)")
            }

        case .sessionEnded:
            print("[EventPeerManager] 🛑 Received termination from host (\(peerID.displayName))")
            Task { @MainActor in
                self.stop()
                self.onSessionEnded?()
            }
        }
    }

    // Required stubs
    nonisolated func session(_: MCSession, didReceive _: InputStream,
                             withName _: String, fromPeer _: MCPeerID) {}
    nonisolated func session(_: MCSession, didStartReceivingResourceWithName _: String,
                             fromPeer _: MCPeerID, with _: Progress) {}
    nonisolated func session(_: MCSession, didFinishReceivingResourceWithName _: String,
                             fromPeer _: MCPeerID, at _: URL?, withError _: Error?) {}

    // Required when encryptionPreference != .none — must call handler or connection is dropped.
    nonisolated func session(_: MCSession, didReceiveCertificate _: [Any]?,
                             fromPeer _: MCPeerID,
                             certificateHandler: @escaping (Bool) -> Void) {
        certificateHandler(true)
    }
}

// MARK: - MCNearbyServiceAdvertiserDelegate

extension EventPeerManager: MCNearbyServiceAdvertiserDelegate {

    nonisolated func advertiser(_ advertiser: MCNearbyServiceAdvertiser,
                                didReceiveInvitationFromPeer peerID: MCPeerID,
                                withContext context: Data?,
                                invitationHandler: @escaping (Bool, MCSession?) -> Void) {
        print("[EventPeerManager] 📨 Accepting invitation from \(peerID.displayName)")
        invitationHandler(true, session)
    }

    nonisolated func advertiser(_: MCNearbyServiceAdvertiser,
                                didNotStartAdvertisingPeer error: Error) {
        print("[EventPeerManager] ❌ Advertiser error: \(error)")
    }
}

// MARK: - MCNearbyServiceBrowserDelegate

extension EventPeerManager: MCNearbyServiceBrowserDelegate {

    nonisolated func browser(_ browser: MCNearbyServiceBrowser,
                             foundPeer peerID: MCPeerID,
                             withDiscoveryInfo info: [String: String]?) {

        // Only connect to peers with the SAME event code
        guard let peerCode = info?["eventCode"] else {
            print("[EventPeerManager] 👀 Ignoring \(peerID.displayName) — no event code")
            return
        }

        // Use the nonisolated(unsafe) copies set in start() — safe read-only access.
        let myCode = _eventCodeForBrowser
        let myName = myPeerID.displayName

        guard peerCode == myCode else {
            print("[EventPeerManager] 👀 Ignoring \(peerID.displayName) — code mismatch (\(peerCode) ≠ \(myCode))")
            return
        }

        // Tie-breaking: only the peer whose display name sorts LOWER sends the
        // invitation. This prevents both sides calling invitePeer() simultaneously,
        // which causes a race where only one side fires .connected reliably.
        // The higher-named peer will receive (and accept) the invitation instead.
        guard myName < peerID.displayName else {
            print("[EventPeerManager] 👀 Found \(peerID.displayName) — waiting for their invite (tie-break)")
            return
        }

        print("[EventPeerManager] 👀 Found \(peerID.displayName) — inviting (code: \(peerCode))")
        browser.invitePeer(peerID, to: session, withContext: nil, timeout: 10)
    }

    nonisolated func browser(_: MCNearbyServiceBrowser, lostPeer peerID: MCPeerID) {
        print("[EventPeerManager] 👋 Lost peer: \(peerID.displayName)")
    }

    nonisolated func browser(_: MCNearbyServiceBrowser,
                             didNotStartBrowsingForPeers error: Error) {
        print("[EventPeerManager] ❌ Browser error: \(error)")
    }
}
