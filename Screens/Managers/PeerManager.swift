import Foundation
import MultipeerConnectivity
import UIKit

/// Manages near-field card transfer via MultipeerConnectivity.
///
/// **Thread model (Swift 6)**
/// • The entire class is @MainActor isolated.
/// • All MC delegate methods are `nonisolated` (required by MC protocols),
///   and they hop back to @MainActor by capturing only Sendable values
///   (String, Bool, CardModel) — never `self`.
/// • `session` is captured in nonisolated delegates as a `nonisolated(unsafe)`
///   let-constant; MPC itself manages its thread-safety.
@MainActor
final class PeerManager: NSObject, ObservableObject {

    // MARK: - @Published

    @Published var isConnected: Bool = false
    @Published var receivedCard: CardModel? = nil
    @Published var statusLabel: String = "Idle"

    // MARK: - MC objects

    private let serviceType = "ecocard-p2p"

    // These are immutable after init; MPC manages their internal thread-safety.
    nonisolated(unsafe) private let myPeerID: MCPeerID
    nonisolated(unsafe) private let session: MCSession

    private var advertiser: MCNearbyServiceAdvertiser?
    private var browser: MCNearbyServiceBrowser?

    private var _isHosting  = false
    private var _isBrowsing = false

    var isHosting:  Bool { _isHosting  }
    var isBrowsing: Bool { _isBrowsing }

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

    // MARK: - Hosting

    func startHosting() {
        guard !_isHosting else { return }
        let adv = MCNearbyServiceAdvertiser(peer: myPeerID,
                                           discoveryInfo: nil,
                                           serviceType: serviceType)
        adv.delegate = self
        adv.startAdvertisingPeer()
        advertiser = adv
        _isHosting = true
        statusLabel = "Waiting for sender…"
        print("[PeerManager] 📡 Advertising started")
    }

    func stopHosting() {
        advertiser?.stopAdvertisingPeer()
        advertiser = nil
        _isHosting = false
        statusLabel = "Idle"
        print("[PeerManager] ⏹ Advertising stopped")
    }

    // MARK: - Browsing

    func startBrowsing() {
        guard !_isBrowsing else { return }
        let b = MCNearbyServiceBrowser(peer: myPeerID, serviceType: serviceType)
        b.delegate = self
        b.startBrowsingForPeers()
        browser = b
        _isBrowsing = true
        statusLabel = "Searching for receiver…"
        print("[PeerManager] 🔍 Browsing started")
    }

    func stopBrowsing() {
        browser?.stopBrowsingForPeers()
        browser = nil
        _isBrowsing = false
        if !isConnected { statusLabel = "Idle" }
        print("[PeerManager] ⏹ Browsing stopped")
    }

    func stopAll() {
        stopHosting()
        stopBrowsing()
        session.disconnect()
        isConnected = false
        statusLabel = "Idle"
    }

    /// Call this when starting a new send (e.g. ShareCardView appears).
    /// Drops any current peers and restarts the browser WITHOUT recreating
    /// the MCSession — this avoids the TLS renegotiation cost and makes
    /// the second (and later) sends just as fast as the first.
    func resetForNewSend() {
        // Drop existing peers on the session but keep the session alive.
        // MPC will notify the other side via the delegate.
        session.disconnect()
        isConnected = false
        hasSentCard = false
        statusLabel = "Searching for receiver…"

        // Restart browser so we can find the next receiver.
        stopBrowsing()
        startBrowsing()
    }

    /// Tracks whether we have already auto-sent within the current share session.
    /// Stored here so ShareCardView can stay stateless about this.
    private(set) var hasSentCard: Bool = false

    /// Call this from ShareCardView after the card is confirmed sent.
    func markCardSent() { hasSentCard = true }

    // MARK: - Send Card

    func sendCard(_ card: CardModel) {
        guard !session.connectedPeers.isEmpty else {
            print("[PeerManager] ⚠️ No peers connected"); return
        }

        // Capture Sendable values before crossing the boundary.
        let peers   = session.connectedPeers
        let session = self.session      // nonisolated(unsafe) let — safe to capture
        let name    = card.fullName

        // JSON encoding can be slow for large payloads — move it off main thread.
        DispatchQueue.global(qos: .userInitiated).async {
            do {
                let data = try JSONEncoder().encode(card)
                // Log size so we know if images are bloating the payload.
                print("[PeerManager] 📦 Payload size: \(data.count) bytes")
                try session.send(data, toPeers: peers, with: .reliable)
                DispatchQueue.main.async { [weak self] in
                    self?.statusLabel = "Card sent ✓"
                    self?.hasSentCard = true
                    print("[PeerManager] ✅ Sent: \(name)")
                }
            } catch {
                print("[PeerManager] ❌ Send error: \(error)")
            }
        }
    }
}

// MARK: - MCSessionDelegate

extension PeerManager: MCSessionDelegate {

    // nonisolated: MPC calls these on arbitrary threads.
    // We capture only Sendable values and hop to @MainActor.

    nonisolated func session(_ session: MCSession,
                             peer peerID: MCPeerID,
                             didChange state: MCSessionState) {

        let connected = !session.connectedPeers.isEmpty
        let label: String
        switch state {
        case .connected:    label = "Connected!"
        case .connecting:   label = "Connecting…"
        case .notConnected: label = connected ? "Connected!" : "Disconnected"
        @unknown default:   label = ""
        }
        let peerName = peerID.displayName
        let stateRaw = state.rawValue

        Task { @MainActor [weak self] in
            guard let self else { return }
            self.isConnected = connected
            if !label.isEmpty { self.statusLabel = label }
            print("[PeerManager] 🔵 \(peerName) → \(stateRaw)")
        }
    }

    nonisolated func session(_ session: MCSession,
                             didReceive data: Data,
                             fromPeer peerID: MCPeerID) {

        // Decode on the background thread — CardModel is Sendable.
        guard var card = try? JSONDecoder().decode(CardModel.self, from: data) else {
            print("[PeerManager] ⚠️ Could not decode received data"); return
        }
        card.isReceived = true
        let senderName = peerID.displayName

        Task { @MainActor [weak self] in
            guard let self else { return }
            self.receivedCard = card
            self.statusLabel  = "Card received from \(senderName)!"
            print("[PeerManager] 📥 Received: \(card.fullName)")
        }
    }

    // Required stubs
    nonisolated func session(_: MCSession, didReceive _: InputStream,
                             withName _: String, fromPeer _: MCPeerID) {}
    nonisolated func session(_: MCSession, didStartReceivingResourceWithName _: String,
                             fromPeer _: MCPeerID, with _: Progress) {}
    nonisolated func session(_: MCSession, didFinishReceivingResourceWithName _: String,
                             fromPeer _: MCPeerID, at _: URL?, withError _: Error?) {}
}

// MARK: - MCNearbyServiceAdvertiserDelegate

extension PeerManager: MCNearbyServiceAdvertiserDelegate {

    nonisolated func advertiser(_ advertiser: MCNearbyServiceAdvertiser,
                                didReceiveInvitationFromPeer peerID: MCPeerID,
                                withContext context: Data?,
                                invitationHandler: @escaping (Bool, MCSession?) -> Void) {
        print("[PeerManager] 📨 Accepting invitation from \(peerID.displayName)")
        // session is nonisolated(unsafe) — safe to pass here.
        invitationHandler(true, session)
    }

    nonisolated func advertiser(_: MCNearbyServiceAdvertiser,
                                didNotStartAdvertisingPeer error: Error) {
        print("[PeerManager] ❌ Advertiser error: \(error)")
    }
}

// MARK: - MCNearbyServiceBrowserDelegate

extension PeerManager: MCNearbyServiceBrowserDelegate {

    nonisolated func browser(_ browser: MCNearbyServiceBrowser,
                             foundPeer peerID: MCPeerID,
                             withDiscoveryInfo _: [String: String]?) {
        print("[PeerManager] 👀 Found \(peerID.displayName) — inviting")
        browser.invitePeer(peerID, to: session, withContext: nil, timeout: 10)
    }

    nonisolated func browser(_: MCNearbyServiceBrowser, lostPeer _: MCPeerID) {}

    nonisolated func browser(_: MCNearbyServiceBrowser,
                             didNotStartBrowsingForPeers error: Error) {
        print("[PeerManager] ❌ Browser error: \(error)")
    }
}
