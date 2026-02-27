import Foundation
import MultipeerConnectivity
import Combine

@MainActor
final class EventModePeerManager: NSObject, ObservableObject {

    // MARK: - UI State

    @Published var connectedPeerCount: Int = 0
    @Published var receivedCards: [CardModel] = []
    @Published var statusLabel: String = "Not Connected"

    // MARK: - Multipeer

    private let serviceType = "ecocardp2p"
    private let maxParticipants = 8

    private let myPeerID = MCPeerID(displayName: UIDevice.current.name)

    nonisolated(unsafe) private let session: MCSession
    nonisolated(unsafe) private var advertiser: MCNearbyServiceAdvertiser?
    nonisolated(unsafe) private var browser: MCNearbyServiceBrowser?

    // MARK: - Event State

    private var eventCode: String = ""
    private var seenCardIDs: Set<UUID> = []
    private let myCard: CardModel

    // MARK: - Init

    init(myCard: CardModel) {
        self.myCard = myCard
        self.session = MCSession(
            peer: myPeerID,
            securityIdentity: nil,
            encryptionPreference: .required
        )

        super.init()
        self.session.delegate = self
    }

    // MARK: - Public API

    func startEventMode(with eventCode: String) {
        self.eventCode = eventCode
        self.seenCardIDs = [myCard.id]

        let advertiser = MCNearbyServiceAdvertiser(
            peer: myPeerID,
            discoveryInfo: ["eventCode": eventCode],
            serviceType: serviceType
        )
        advertiser.delegate = self
        advertiser.startAdvertisingPeer()
        self.advertiser = advertiser

        let browser = MCNearbyServiceBrowser(
            peer: myPeerID,
            serviceType: serviceType
        )
        browser.delegate = self
        browser.startBrowsingForPeers()
        self.browser = browser

        statusLabel = "Event Mode Active"
    }

    func stopEventMode() {
        advertiser?.stopAdvertisingPeer()
        browser?.stopBrowsingForPeers()
        session.disconnect()

        connectedPeerCount = 0
        statusLabel = "Disconnected"
        seenCardIDs.removeAll()
    }

    // MARK: - Sending

    private func sendMyCard(to peer: MCPeerID) {
        guard let data = try? JSONEncoder().encode(myCard) else { return }
        try? session.send(data, toPeers: [peer], with: .reliable)
    }

    private func rebroadcast(_ card: CardModel, excluding sender: MCPeerID) {
        let peers = session.connectedPeers.filter { $0 != sender }
        guard !peers.isEmpty else { return }

        guard let data = try? JSONEncoder().encode(card) else { return }
        try? session.send(data, toPeers: peers, with: .reliable)
    }

    private func handleReceivedCard(_ card: CardModel, from sender: MCPeerID) {
        guard !seenCardIDs.contains(card.id) else { return }

        seenCardIDs.insert(card.id)
        receivedCards.append(card)
        rebroadcast(card, excluding: sender)
    }
}
extension EventModePeerManager: MCSessionDelegate {

    nonisolated func session(_ session: MCSession,
                             peer peerID: MCPeerID,
                             didChange state: MCSessionState) {
        let peerCount = session.connectedPeers.count
        let stateValue = state

        Task { @MainActor [weak self] in
            guard let self else { return }

            self.connectedPeerCount = peerCount

            switch stateValue {
            case .connected:
                self.statusLabel = "Connected: \(peerCount)"
                self.sendMyCard(to: peerID)

                if peerCount >= self.maxParticipants - 1 {
                    self.browser?.stopBrowsingForPeers()
                }

            case .notConnected:
                self.statusLabel = "Disconnected"

            case .connecting:
                self.statusLabel = "Connecting..."

            @unknown default:
                break
            }
        }
    }

    nonisolated func session(_ session: MCSession,
                             didReceive data: Data,
                             fromPeer peerID: MCPeerID) {
        guard let card = try? JSONDecoder().decode(CardModel.self, from: data) else { return }

        Task { @MainActor [weak self] in
            self?.handleReceivedCard(card, from: peerID)
        }
    }

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

    nonisolated func session(_ session: MCSession,
                             didReceiveCertificate certificate: [Any]?,
                             fromPeer peerID: MCPeerID,
                             certificateHandler: @escaping (Bool) -> Void) {
        certificateHandler(true)
    }
}
extension EventModePeerManager: MCNearbyServiceAdvertiserDelegate {

    nonisolated func advertiser(_ advertiser: MCNearbyServiceAdvertiser,
                                didReceiveInvitationFromPeer peerID: MCPeerID,
                                withContext context: Data?,
                                invitationHandler: @escaping (Bool, MCSession?) -> Void) {

        invitationHandler(true, session)
    }
}
extension EventModePeerManager: MCNearbyServiceBrowserDelegate {

    nonisolated func browser(_ browser: MCNearbyServiceBrowser,
                             foundPeer peerID: MCPeerID,
                             withDiscoveryInfo info: [String : String]?) {

        guard let discoveredCode = info?["eventCode"] else { return }

        Task { @MainActor [weak self] in
            guard let self else { return }
            guard discoveredCode == self.eventCode else { return }

            if self.connectedPeerCount < self.maxParticipants - 1 {
                self.session.connectPeer(peerID, withNearbyConnectionData: Data())
            }
        }
    }

    nonisolated func browser(_ browser: MCNearbyServiceBrowser,
                             lostPeer peerID: MCPeerID) {}
}
