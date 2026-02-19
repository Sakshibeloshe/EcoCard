import Foundation
import MultipeerConnectivity
import UIKit

// MARK: - Transfer State Machine

enum TransferRole {
    case none
    case sender
    case receiver
}

enum TransferState: Equatable {
    case idle
    case advertising
    case browsing
    case connecting(String)
    case connected(String)
    case sending
    case receiving
    case sent
    case received
    case failed(String)
}

// MARK: - PeerTransferManager

final class PeerTransferManager: NSObject, ObservableObject, @unchecked Sendable {

    @Published var role: TransferRole = .none
    @Published var state: TransferState = .idle

    /// Called on the receiver side when a card arrives.
    var onCardReceived: ((CardTransferPayload) -> Void)?

    private let serviceType = "ecocard-xfer" // ≤ 15 chars, lowercase, letters/numbers/hyphen only
    private var peerID: MCPeerID!
    private var session: MCSession!
    private var advertiser: MCNearbyServiceAdvertiser?
    private var browser: MCNearbyServiceBrowser?

    override init() {
        super.init()
        peerID = MCPeerID(displayName: UIDevice.current.name)
        session = MCSession(peer: peerID, securityIdentity: nil, encryptionPreference: .required)
        session.delegate = self
    }

    // MARK: - Sender

    func startSenderMode() {
        role = .sender
        state = .advertising
        advertiser = MCNearbyServiceAdvertiser(peer: peerID, discoveryInfo: nil, serviceType: serviceType)
        advertiser?.delegate = self
        advertiser?.startAdvertisingPeer()
    }

    func stopSenderMode() {
        advertiser?.stopAdvertisingPeer()
        advertiser = nil
        session.disconnect()
        role = .none
        state = .idle
    }

    // MARK: - Receiver

    func startReceiverMode() {
        role = .receiver
        state = .browsing
        browser = MCNearbyServiceBrowser(peer: peerID, serviceType: serviceType)
        browser?.delegate = self
        browser?.startBrowsingForPeers()
    }

    func stopReceiverMode() {
        browser?.stopBrowsingForPeers()
        browser = nil
        session.disconnect()
        role = .none
        state = .idle
    }

    // MARK: - Send Card

    func sendCard(_ payload: CardTransferPayload) {
        guard !session.connectedPeers.isEmpty else {
            DispatchQueue.main.async { self.state = .failed("No receiver connected") }
            return
        }
        do {
            DispatchQueue.main.async { self.state = .sending }
            let data = try JSONEncoder().encode(payload)
            try session.send(data, toPeers: session.connectedPeers, with: .reliable)
            DispatchQueue.main.async { self.state = .sent }
        } catch {
            DispatchQueue.main.async {
                self.state = .failed("Send failed: \(error.localizedDescription)")
            }
        }
    }
}

// MARK: - MCNearbyServiceAdvertiserDelegate (Sender side)

extension PeerTransferManager: MCNearbyServiceAdvertiserDelegate {
    func advertiser(
        _ advertiser: MCNearbyServiceAdvertiser,
        didReceiveInvitationFromPeer peerID: MCPeerID,
        withContext context: Data?,
        invitationHandler: @escaping (Bool, MCSession?) -> Void
    ) {
        let name = peerID.displayName
        DispatchQueue.main.async { self.state = .connecting(name) }
        invitationHandler(true, session) // auto-accept
    }

    func advertiser(_ advertiser: MCNearbyServiceAdvertiser, didNotStartAdvertisingPeer error: Error) {
        DispatchQueue.main.async { self.state = .failed("Advertiser error: \(error.localizedDescription)") }
    }
}

// MARK: - MCNearbyServiceBrowserDelegate (Receiver side)

extension PeerTransferManager: MCNearbyServiceBrowserDelegate {
    func browser(
        _ browser: MCNearbyServiceBrowser,
        foundPeer peerID: MCPeerID,
        withDiscoveryInfo info: [String: String]?
    ) {
        let name = peerID.displayName
        DispatchQueue.main.async { self.state = .connecting(name) }
        browser.invitePeer(peerID, to: session, withContext: nil, timeout: 15)
    }

    func browser(_ browser: MCNearbyServiceBrowser, lostPeer peerID: MCPeerID) {}

    func browser(_ browser: MCNearbyServiceBrowser, didNotStartBrowsingForPeers error: Error) {
        DispatchQueue.main.async { self.state = .failed("Browser error: \(error.localizedDescription)") }
    }
}

// MARK: - MCSessionDelegate (Both sides)

extension PeerTransferManager: MCSessionDelegate {

    func session(_ session: MCSession, peer peerID: MCPeerID, didChange state: MCSessionState) {
        let name = peerID.displayName
        DispatchQueue.main.async {
            switch state {
            case .connected:    self.state = .connected(name)
            case .connecting:   self.state = .connecting(name)
            case .notConnected: self.state = .failed("Disconnected from \(name)")
            @unknown default:   break
            }
        }
    }

    func session(_ session: MCSession, didReceive data: Data, fromPeer peerID: MCPeerID) {
        DispatchQueue.main.async { self.state = .receiving }
        do {
            let payload = try JSONDecoder().decode(CardTransferPayload.self, from: data)
            DispatchQueue.main.async {
                self.onCardReceived?(payload)
                self.state = .received
                UINotificationFeedbackGenerator().notificationOccurred(.success)
            }
        } catch {
            DispatchQueue.main.async { self.state = .failed("Decode failed: \(error.localizedDescription)") }
        }
    }

    // Required stubs
    func session(_ session: MCSession, didReceive stream: InputStream, withName streamName: String, fromPeer peerID: MCPeerID) {}
    func session(_ session: MCSession, didStartReceivingResourceWithName resourceName: String, fromPeer peerID: MCPeerID, with progress: Progress) {}
    func session(_ session: MCSession, didFinishReceivingResourceWithName resourceName: String, fromPeer peerID: MCPeerID, at localURL: URL?, withError error: Error?) {}
}
