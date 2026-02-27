@preconcurrency import MultipeerConnectivity
import Foundation
import Combine

/// Handles event-mode group card exchange via MultipeerConnectivity.
///
/// **Swift 6 thread model:**
/// • `@MainActor` isolates all mutable state to the main actor.
/// • Delegate methods are `nonisolated` (required by MC protocols).
/// • In delegates, only Sendable values (Int, String, Data, CardModel) are
///   captured before crossing to `Task { @MainActor in }`.
/// • `: @unchecked Sendable` satisfies the compiler — all mutation happens
///   under `@MainActor`, so the claim is true.
@MainActor
final class EventModePeerManager: NSObject, ObservableObject, @unchecked Sendable {

    // MARK: - UI State

    @Published var connectedPeerCount: Int = 0
    @Published var receivedCards: [CardModel] = []
    @Published var statusLabel: String = "Not Connected"

    // MARK: - Multipeer

    private let serviceType = "ecocardp2p"
    private let maxParticipants = 8

    // Immutable after init; MPC manages its own thread-safety.
    nonisolated(unsafe) private let myPeerID: MCPeerID
    nonisolated(unsafe) private let session: MCSession

    private var advertiser: MCNearbyServiceAdvertiser?
    private var browser: MCNearbyServiceBrowser?

    // MARK: - Event State

    private var eventCode: String = ""
    private var seenCardIDs: Set<UUID> = []
    private var myCard: CardModel?

    // MARK: - Init

    override init() {
        // UIDevice.current requires @MainActor — fine here because the
        // class is @MainActor and init runs on the main actor.
        let name = UIDevice.current.name
        let peerID = MCPeerID(displayName: name.isEmpty ? "EcoCard User" : name)
        self.myPeerID = peerID
        self.session = MCSession(
            peer: peerID,
            securityIdentity: nil,
            encryptionPreference: .required
        )
        super.init()
        self.session.delegate = self
    }

    // MARK: - Public API

    func startEventMode(eventCode: String, card: CardModel) {
        guard advertiser == nil else { return }   // already running

        self.eventCode = eventCode
        self.myCard = card
        self.seenCardIDs = [card.id]

        let adv = MCNearbyServiceAdvertiser(
            peer: myPeerID,
            discoveryInfo: ["eventCode": eventCode],
            serviceType: serviceType
        )
        adv.delegate = self
        adv.startAdvertisingPeer()
        advertiser = adv

        let b = MCNearbyServiceBrowser(peer: myPeerID, serviceType: serviceType)
        b.delegate = self
        b.startBrowsingForPeers()
        browser = b

        statusLabel = "Event Mode Active"
    }

    func stopEventMode() {
        advertiser?.stopAdvertisingPeer()
        advertiser = nil
        browser?.stopBrowsingForPeers()
        browser = nil
        session.disconnect()

        connectedPeerCount = 0
        statusLabel = "Disconnected"
        seenCardIDs.removeAll()
        myCard = nil
    }

    // MARK: - Sending

    private func sendMyCard(to peer: MCPeerID) {
        guard let card = myCard,
              let data = try? JSONEncoder().encode(card) else { return }
        try? session.send(data, toPeers: [peer], with: .reliable)
    }

    private func rebroadcast(_ data: Data, excluding sender: MCPeerID) {
        let peers = session.connectedPeers.filter { $0 != sender }
        guard !peers.isEmpty else { return }
        try? session.send(data, toPeers: peers, with: .reliable)
    }

    private func handleReceivedCard(_ card: CardModel, rawData: Data, from sender: MCPeerID) {
        guard !seenCardIDs.contains(card.id) else { return }
        seenCardIDs.insert(card.id)
        receivedCards.append(card)
        rebroadcast(rawData, excluding: sender)
    }
}

// MARK: - MCSessionDelegate

extension EventModePeerManager: MCSessionDelegate {

    nonisolated func session(_ session: MCSession,
                             peer peerID: MCPeerID,
                             didChange state: MCSessionState) {
        // Capture only Sendable values before crossing to main actor.
        let peerCount = session.connectedPeers.count
        let peerName  = peerID.displayName
        let stateRaw  = state

        Task { @MainActor [weak self] in
            guard let self else { return }
            self.connectedPeerCount = peerCount

            switch stateRaw {
            case .connected:
                self.statusLabel = "Connected: \(peerCount)"
                self.sendMyCard(to: peerID)
                if peerCount >= self.maxParticipants - 1 {
                    self.browser?.stopBrowsingForPeers()
                }
            case .notConnected:
                self.statusLabel = peerCount > 0
                    ? "\(peerCount) connected"
                    : "Disconnected"
            case .connecting:
                self.statusLabel = "Connecting…"
            @unknown default:
                break
            }
            print("[EventModePeerManager] \(peerName) → \(stateRaw.rawValue)")
        }
    }

    nonisolated func session(_ session: MCSession,
                             didReceive data: Data,
                             fromPeer peerID: MCPeerID) {
        guard var card = try? JSONDecoder().decode(CardModel.self, from: data) else { return }
        card.isReceived = true
        let snapshot = data   // already a value type (Data is Sendable)

        Task { @MainActor [weak self] in
            self?.handleReceivedCard(card, rawData: snapshot, from: peerID)
        }
    }

    // Required no-op stubs
    nonisolated func session(_: MCSession, didReceive _: InputStream,
                             withName _: String, fromPeer _: MCPeerID) {}
    nonisolated func session(_: MCSession, didStartReceivingResourceWithName _: String,
                             fromPeer _: MCPeerID, with _: Progress) {}
    nonisolated func session(_: MCSession, didFinishReceivingResourceWithName _: String,
                             fromPeer _: MCPeerID, at _: URL?, withError _: Error?) {}
    nonisolated func session(_: MCSession, didReceiveCertificate _: [Any]?,
                             fromPeer _: MCPeerID,
                             certificateHandler: @escaping (Bool) -> Void) {
        certificateHandler(true)
    }
}

// MARK: - MCNearbyServiceAdvertiserDelegate

extension EventModePeerManager: MCNearbyServiceAdvertiserDelegate {

    nonisolated func advertiser(_ advertiser: MCNearbyServiceAdvertiser,
                                didReceiveInvitationFromPeer peerID: MCPeerID,
                                withContext context: Data?,
                                invitationHandler: @escaping (Bool, MCSession?) -> Void) {
        // session is nonisolated(unsafe) let — safe to pass here.
        invitationHandler(true, session)
    }

    nonisolated func advertiser(_: MCNearbyServiceAdvertiser,
                                didNotStartAdvertisingPeer error: Error) {
        print("[EventModePeerManager] ❌ Advertiser error: \(error)")
    }
}

// MARK: - MCNearbyServiceBrowserDelegate

extension EventModePeerManager: MCNearbyServiceBrowserDelegate {

    nonisolated func browser(_ browser: MCNearbyServiceBrowser,
                             foundPeer peerID: MCPeerID,
                             withDiscoveryInfo info: [String: String]?) {
        guard let discoveredCode = info?["eventCode"] else { return }
        let peerName = peerID.displayName

        Task { @MainActor [weak self] in
            guard let self else { return }
            guard discoveredCode == self.eventCode else { return }

            if self.connectedPeerCount < self.maxParticipants - 1 {
                print("[EventModePeerManager] 👀 Inviting \(peerName)")
                browser.invitePeer(peerID, to: self.session, withContext: nil, timeout: 10)
            }
        }
    }

    nonisolated func browser(_: MCNearbyServiceBrowser, lostPeer _: MCPeerID) {}

    nonisolated func browser(_: MCNearbyServiceBrowser,
                             didNotStartBrowsingForPeers error: Error) {
        print("[EventModePeerManager] ❌ Browser error: \(error)")
    }
}
