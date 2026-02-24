import Foundation
import MultipeerConnectivity
import Combine

/// Manages near‑field card transfer using MultipeerConnectivity.
///
/// **Receiver flow**: call `startHosting()` → the device advertises itself.
/// **Sender flow**: call `startBrowsing()` → the manager auto‑invites
/// any nearby advertiser and, once connected, calls the `onConnected`
/// closure so the caller can send. Call `sendCard(_:)` at any time
/// once `isConnected` is true.
@MainActor
final class PeerManager: NSObject, ObservableObject {

    // MARK: - Published state

    /// `true` when at least one peer is connected.
    @Published var isConnected: Bool = false

    /// Set to the last card received via MultipeerConnectivity.
    /// Observe this in the UI to auto‑save / show an alert.
    @Published var receivedCard: CardModel? = nil

    /// Friendly status string for display in the UI.
    @Published var statusLabel: String = "Idle"

    // MARK: - Private MC objects

    private let serviceType = "ecocard-p2p"

    // Each instance gets a fresh random peer ID so the user can run
    // multiple sessions without collisions.
    private let myPeerID = MCPeerID(displayName: UIDevice.current.name)

    private var session: MCSession!
    private var advertiser: MCNearbyServiceAdvertiser?
    private var browser: MCNearbyServiceBrowser?

    /// `true` while this device is actively advertising (receiver).
    private(set) var isHosting = false

    /// `true` while this device is actively browsing (sender).
    private(set) var isBrowsing = false

    // MARK: - Init

    override init() {
        super.init()
        session = MCSession(
            peer: myPeerID,
            securityIdentity: nil,
            encryptionPreference: .required
        )
        session.delegate = self
    }

    // MARK: - Advertising (Receiver)

    func startHosting() {
        guard !isHosting else { return }
        advertiser = MCNearbyServiceAdvertiser(
            peer: myPeerID,
            discoveryInfo: nil,
            serviceType: serviceType
        )
        advertiser?.delegate = self
        advertiser?.startAdvertisingPeer()
        isHosting = true
        statusLabel = "Waiting for sender…"
        print("[PeerManager] 📡 Advertising started")
    }

    func stopHosting() {
        advertiser?.stopAdvertisingPeer()
        advertiser = nil
        isHosting = false
        statusLabel = "Idle"
        print("[PeerManager] ⏹ Advertising stopped")
    }

    // MARK: - Browsing (Sender)

    func startBrowsing() {
        guard !isBrowsing else { return }
        browser = MCNearbyServiceBrowser(peer: myPeerID, serviceType: serviceType)
        browser?.delegate = self
        browser?.startBrowsingForPeers()
        isBrowsing = true
        statusLabel = "Searching for receiver…"
        print("[PeerManager] 🔍 Browsing started")
    }

    func stopBrowsing() {
        browser?.stopBrowsingForPeers()
        browser = nil
        isBrowsing = false
        if !isConnected { statusLabel = "Idle" }
        print("[PeerManager] ⏹ Browsing stopped")
    }

    // MARK: - Stop everything

    func stopAll() {
        stopHosting()
        stopBrowsing()
        session.disconnect()
        isConnected = false
        statusLabel = "Idle"
    }

    // MARK: - Send

    func sendCard(_ card: CardModel) {
        guard isConnected, !session.connectedPeers.isEmpty else {
            print("[PeerManager] ⚠️ No peers — cannot send")
            return
        }
        do {
            let data = try JSONEncoder().encode(card)
            try session.send(data, toPeers: session.connectedPeers, with: .reliable)
            statusLabel = "Card sent ✓"
            print("[PeerManager] ✅ Card sent: \(card.fullName)")
        } catch {
            print("[PeerManager] ❌ Send error: \(error)")
        }
    }
}

// MARK: - MCSessionDelegate

extension PeerManager: MCSessionDelegate {

    nonisolated func session(_ session: MCSession,
                             peer peerID: MCPeerID,
                             didChange state: MCSessionState) {
        Task { @MainActor in
            let connected = !session.connectedPeers.isEmpty
            self.isConnected = connected
            switch state {
            case .connected:
                self.statusLabel = "Connected!"
                print("[PeerManager] 🟢 Connected: \(peerID.displayName)")
            case .connecting:
                self.statusLabel = "Connecting…"
                print("[PeerManager] 🟡 Connecting: \(peerID.displayName)")
            case .notConnected:
                self.statusLabel = connected ? "Connected!" : "Disconnected"
                print("[PeerManager] 🔴 Disconnected: \(peerID.displayName)")
            @unknown default:
                break
            }
        }
    }

    nonisolated func session(_ session: MCSession,
                             didReceive data: Data,
                             fromPeer peerID: MCPeerID) {
        Task { @MainActor in
            if var card = try? JSONDecoder().decode(CardModel.self, from: data) {
                card.isReceived = true
                self.receivedCard = card
                self.statusLabel = "Card received from \(card.fullName)!"
                print("[PeerManager] 📥 Received card: \(card.fullName)")
            } else {
                print("[PeerManager] ⚠️ Could not decode received data")
            }
        }
    }

    // Required but unused stubs
    nonisolated func session(_ session: MCSession,
                             didReceive stream: InputStream,
                             withName streamName: String,
                             fromPeer peerID: MCPeerID) {}

    nonisolated func session(_ session: MCSession,
                             didStartReceivingResourceWithName resourceName: String,
                             fromPeer peerID: MCPeerID,
                             with progress: Progress) {}

    nonisolated func session(_ session: MCSession,
                             didFinishReceivingResourceWithName resourceName: String,
                             fromPeer peerID: MCPeerID,
                             at localURL: URL?,
                             withError error: Error?) {}
}

// MARK: - MCNearbyServiceAdvertiserDelegate

extension PeerManager: MCNearbyServiceAdvertiserDelegate {

    nonisolated func advertiser(_ advertiser: MCNearbyServiceAdvertiser,
                                didReceiveInvitationFromPeer peerID: MCPeerID,
                                withContext context: Data?,
                                invitationHandler: @escaping (Bool, MCSession?) -> Void) {
        // Auto‑accept every invitation — the app display controls who is a receiver.
        print("[PeerManager] 📨 Invitation from \(peerID.displayName) — accepting")
        invitationHandler(true, session)
    }

    nonisolated func advertiser(_ advertiser: MCNearbyServiceAdvertiser,
                                didNotStartAdvertisingPeer error: Error) {
        print("[PeerManager] ❌ Advertiser error: \(error)")
    }
}

// MARK: - MCNearbyServiceBrowserDelegate

extension PeerManager: MCNearbyServiceBrowserDelegate {

    nonisolated func browser(_ browser: MCNearbyServiceBrowser,
                             foundPeer peerID: MCPeerID,
                             withDiscoveryInfo info: [String: String]?) {
        print("[PeerManager] 👀 Found peer: \(peerID.displayName) — inviting")
        browser.invitePeer(peerID, to: session, withContext: nil, timeout: 10)
    }

    nonisolated func browser(_ browser: MCNearbyServiceBrowser,
                             lostPeer peerID: MCPeerID) {
        print("[PeerManager] 👋 Lost peer: \(peerID.displayName)")
    }

    nonisolated func browser(_ browser: MCNearbyServiceBrowser,
                             didNotStartBrowsingForPeers error: Error) {
        print("[PeerManager] ❌ Browser error: \(error)")
    }
}
