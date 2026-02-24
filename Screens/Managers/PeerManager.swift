import Foundation
import MultipeerConnectivity
import Combine
import UIKit

@MainActor
final class PeerManager: NSObject, ObservableObject {

    // MARK: - Published UI State (must update on MainActor)

    @Published var isConnected: Bool = false
    @Published var receivedCard: CardModel? = nil
    @Published var statusLabel: String = "Idle"

    // MARK: - Multipeer Properties

    private let serviceType = "ecocard-p2p"

    nonisolated private let myPeerID: MCPeerID
    nonisolated private let session: MCSession

    private var advertiser: MCNearbyServiceAdvertiser?
    private var browser: MCNearbyServiceBrowser?

    private(set) var isHosting = false
    private(set) var isBrowsing = false

    // MARK: - Init

    override init() {
        let deviceName = UIDevice.current.name
        self.myPeerID = MCPeerID(displayName: deviceName)

        self.session = MCSession(
            peer: self.myPeerID,
            securityIdentity: nil,
            encryptionPreference: .required
        )

        super.init()
        self.session.delegate = self
    }

    // MARK: - Hosting

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

    // MARK: - Browsing

    func startBrowsing() {
        guard !isBrowsing else { return }

        browser = MCNearbyServiceBrowser(
            peer: myPeerID,
            serviceType: serviceType
        )

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

        if !isConnected {
            statusLabel = "Idle"
        }
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
        guard !session.connectedPeers.isEmpty else { return }

        do {
            let data = try JSONEncoder().encode(card)
            try session.send(data, toPeers: session.connectedPeers, with: .reliable)
            statusLabel = "Card sent ✓"
            print("[PeerManager] ✅ Card sent: \(card.fullName)")
        } catch {
            print("Send error:", error)
        }
    }
}

//////////////////////////////////////////////////////////////
// MARK: - MCSessionDelegate
//////////////////////////////////////////////////////////////

extension PeerManager: MCSessionDelegate {

    nonisolated func session(_ session: MCSession,
                             peer peerID: MCPeerID,
                             didChange state: MCSessionState) {

        let isConnectedNow = !session.connectedPeers.isEmpty

        Task { @MainActor [weak self] in
            guard let self else { return }

            self.isConnected = isConnectedNow

            switch state {
            case .connected:
                self.statusLabel = "Connected!"
            case .connecting:
                self.statusLabel = "Connecting…"
            case .notConnected:
                self.statusLabel = isConnectedNow ? "Connected!" : "Disconnected"
            @unknown default:
                break
            }
        }
    }

    nonisolated func session(_ session: MCSession,
                             didReceive data: Data,
                             fromPeer peerID: MCPeerID) {

        guard let card = try? JSONDecoder().decode(CardModel.self, from: data) else {
            return
        }

        Task { @MainActor [weak self] in
            guard let self else { return }
            self.receivedCard = card
            self.statusLabel = "Card received from \(card.fullName)!"
        }
    }

    // Required stubs

    nonisolated func session(_: MCSession,
                             didReceive _: InputStream,
                             withName _: String,
                             fromPeer _: MCPeerID) {}

    nonisolated func session(_: MCSession,
                             didStartReceivingResourceWithName _: String,
                             fromPeer _: MCPeerID,
                             with _: Progress) {}

    nonisolated func session(_: MCSession,
                             didFinishReceivingResourceWithName _: String,
                             fromPeer _: MCPeerID,
                             at _: URL?,
                             withError _: Error?) {}
}

//////////////////////////////////////////////////////////////
// MARK: - Advertiser Delegate
//////////////////////////////////////////////////////////////

extension PeerManager: MCNearbyServiceAdvertiserDelegate {

    nonisolated func advertiser(_ advertiser: MCNearbyServiceAdvertiser,
                                didReceiveInvitationFromPeer peerID: MCPeerID,
                                withContext context: Data?,
                                invitationHandler: @escaping (Bool, MCSession?) -> Void) {

        // No UI mutation here — no actor hop needed
        invitationHandler(true, session)
    }

    nonisolated func advertiser(_: MCNearbyServiceAdvertiser,
                                didNotStartAdvertisingPeer error: Error) {
        print("Advertiser error:", error)
    }
}

//////////////////////////////////////////////////////////////
// MARK: - Browser Delegate
//////////////////////////////////////////////////////////////

extension PeerManager: MCNearbyServiceBrowserDelegate {

    nonisolated func browser(_ browser: MCNearbyServiceBrowser,
                             foundPeer peerID: MCPeerID,
                             withDiscoveryInfo _: [String : String]?) {

        browser.invitePeer(peerID,
                           to: session,
                           withContext: nil,
                           timeout: 10)
    }

    nonisolated func browser(_: MCNearbyServiceBrowser,
                             lostPeer _: MCPeerID) {}

    nonisolated func browser(_: MCNearbyServiceBrowser,
                             didNotStartBrowsingForPeers error: Error) {
        print("Browser error:", error)
    }
}
