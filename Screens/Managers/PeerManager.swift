import Foundation
import MultipeerConnectivity
import UIKit

/// Manages near-field card transfer via MultipeerConnectivity.
///
/// **Thread model (Swift 6)**
/// • All MC delegate callbacks arrive on arbitrary threads.
/// • Published state is mutated only via `MainActor.run { }`.
/// • `session`, `myPeerID` are `nonisolated(unsafe)` constants that
///   MultipeerConnectivity itself is responsible for thread-safety on.
///
/// The class itself is **not** `@MainActor`-isolated so that it can
/// freely implement the MC delegate protocols (which are nonisolated).
/// UI-bound @Published updates are always hopped to the main actor.
final class PeerManager: NSObject, ObservableObject {

    // MARK: - @Published (mutated only on MainActor)

    @Published var isConnected: Bool = false
    @Published var receivedCard: CardModel? = nil
    @Published var statusLabel: String = "Idle"

    // MARK: - MC objects (safe to access cross-thread per MC's own docs)

    private let serviceType = "ecocard-p2p"

    // nonisolated(unsafe) — we never mutate these after init; MPC
    // manages their thread-safety internally.
    nonisolated(unsafe) private let myPeerID: MCPeerID
    nonisolated(unsafe) private let session: MCSession

    // Advertiser / browser — only accessed from the main thread
    // (started/stopped from SwiftUI button callbacks).
    private var advertiser: MCNearbyServiceAdvertiser?
    private var browser: MCNearbyServiceBrowser?

    private var _isHosting = false
    private var _isBrowsing = false

    var isHosting:  Bool { _isHosting  }
    var isBrowsing: Bool { _isBrowsing }

    // MARK: - Init

    override init() {
        // MCPeerID and MCSession construction is safe before actor isolation.
        let name = UIDevice.current.name
        myPeerID = MCPeerID(displayName: name.isEmpty ? "EcoCard User" : name)
        session  = MCSession(peer: myPeerID,
                             securityIdentity: nil,
                             encryptionPreference: .required)
        super.init()
        session.delegate = self
    }

    // MARK: - Hosting  (call from main thread / SwiftUI)

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

    // MARK: - Browsing  (call from main thread / SwiftUI)

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

    // MARK: - Send Card

    func sendCard(_ card: CardModel) {
        guard !session.connectedPeers.isEmpty else {
            print("[PeerManager] ⚠️ No peers connected"); return
        }
        do {
            let data = try JSONEncoder().encode(card)
            try session.send(data, toPeers: session.connectedPeers, with: .reliable)
            statusLabel = "Card sent ✓"
            print("[PeerManager] ✅ Sent: \(card.fullName)")
        } catch {
            print("[PeerManager] ❌ Send error: \(error)")
        }
    }

    // MARK: - Private helpers

    /// Safely mutate @Published properties on the main actor.
    private func updateUI(_ work: @escaping @MainActor @Sendable () -> Void) {
        Task { @MainActor in work() }
    }
}

// MARK: - MCSessionDelegate

extension PeerManager: MCSessionDelegate {

    func session(_ session: MCSession,
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

        updateUI {
            self.isConnected = connected
            if !label.isEmpty { self.statusLabel = label }
            print("[PeerManager] 🔵 \(peerID.displayName) → \(state.rawValue)")
        }
    }

    func session(_ session: MCSession,
                 didReceive data: Data,
                 fromPeer peerID: MCPeerID) {

        // Decode on the calling (background) thread — CardModel is Sendable
        guard var card = try? JSONDecoder().decode(CardModel.self, from: data) else {
            print("[PeerManager] ⚠️ Could not decode received data"); return
        }
        card.isReceived = true

        updateUI {
            self.receivedCard = card
            self.statusLabel  = "Card received from \(card.fullName)!"
            print("[PeerManager] 📥 Received: \(card.fullName)")
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

extension PeerManager: MCNearbyServiceAdvertiserDelegate {

    func advertiser(_ advertiser: MCNearbyServiceAdvertiser,
                    didReceiveInvitationFromPeer peerID: MCPeerID,
                    withContext context: Data?,
                    invitationHandler: @escaping (Bool, MCSession?) -> Void) {
        print("[PeerManager] 📨 Accepting invitation from \(peerID.displayName)")
        invitationHandler(true, session)
    }

    func advertiser(_: MCNearbyServiceAdvertiser,
                    didNotStartAdvertisingPeer error: Error) {
        print("[PeerManager] ❌ Advertiser error: \(error)")
    }
}

// MARK: - MCNearbyServiceBrowserDelegate

extension PeerManager: MCNearbyServiceBrowserDelegate {

    func browser(_ browser: MCNearbyServiceBrowser,
                 foundPeer peerID: MCPeerID,
                 withDiscoveryInfo _: [String: String]?) {
        print("[PeerManager] 👀 Found \(peerID.displayName) — inviting")
        browser.invitePeer(peerID, to: session, withContext: nil, timeout: 10)
    }

    func browser(_: MCNearbyServiceBrowser, lostPeer _: MCPeerID) {}

    func browser(_: MCNearbyServiceBrowser,
                 didNotStartBrowsingForPeers error: Error) {
        print("[PeerManager] ❌ Browser error: \(error)")
    }
}
